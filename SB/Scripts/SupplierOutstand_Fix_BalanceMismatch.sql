/*======================================================================
  SB2 — Fix Supplier Outstand Summary Closing vs Opening / Detail mismatch

  Root cause (live dbo.SupplierOutstand):
    1. Opening used hardcoded @OpDate = '2025-04-06' while Closing used
       SupplierOpening Date = '2025-01-28' → Closing base wrong.
    2. Filters drifted from dbo.GetSupplierBalance (reference live balance):
       - PaymentID = 2 only (truth: PaymentID IN (2,5))
       - IE without DetailAccountID = 26
       - no isOpening sign flip on SupplierOpeningDetail
       - OpDate not = Max(Date) from SupplierOpeningHead
    3. Period movements posted Purchase as (TotalAmount-PaidAmount) AND also
       posted PaidAmount again as Income/Expense → Payment double-count vs
       Opening/Closing which already use net (TotalAmount-PaidAmount).

  This script CREATE OR ALTERs dbo.SupplierOutstand only.
  dbo.SupplierOutstandHistory / GetSupplierBalance are left unchanged
  (History pivots AccountName labels; Closing must be correct in the SP).

  Deploy: run once on SB2 in SSMS (entire script). No client rebuild required
  for the Summary report (SP-only). Re-run Supplier Outstand Summary after.
======================================================================*/
USE [SB2];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[SupplierOutstand]
(
	@FromDate Datetime,
	@ToDate Datetime,
	@Division nvarchar(1024) = null,
	@Township nvarchar(1024) = null,
	@Supplier nvarchar(1024) = null,
	@UserID int
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @OpDate Datetime, @PreDate Datetime

	-- Latest opening on/before report FromDate (period-safe; not a future opening)
	SELECT @OpDate = MAX([Date])
	FROM SupplierOpeningHead
	WHERE ISNULL(Deleted, 0) <> 1
	  AND [Date] <= @FromDate

	IF @OpDate IS NULL
		SELECT @OpDate = MAX([Date])
		FROM SupplierOpeningHead
		WHERE ISNULL(Deleted, 0) <> 1

	IF @OpDate IS NULL
		SET @OpDate = CONVERT(datetime, '19000101')

	SET @PreDate = DATEADD(d, -1, @FromDate)

	DELETE FROM GeneralLedgerDetail WHERE UserID = @UserID

	DECLARE @Code nvarchar(max)
	CREATE TABLE #Customer (c_id int)

	IF LEN(@Supplier) > 0
		SET @Code = 'insert into #Customer select ID From Supplier Where ID in (' + @Supplier + ')'
	ELSE IF LEN(@Township) > 0
		SET @Code = 'insert into #Customer select ID From Supplier Where TownshipID in (' + @Township + ')'
	ELSE IF LEN(@Division) > 0
		SET @Code = 'insert into #Customer select ID From Supplier C Join Township T on C.TownshipID = T.ID Where DivisionId in (' + @Division + ')'
	ELSE
		SET @Code = 'insert into #Customer select ID From Supplier Where isnull(Deleted,0)<>1'

	EXEC (@Code)

	/* ---------- Opening (@OpDate .. @PreDate), same filters as Closing ---------- */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, @FromDate, DocumentID = '   ', LedgerName = C.Name, AccountName = 'Opening', AccountHeader = '', Amount = SUM(Amount)
	FROM
	(
		-- isOpening sign flip (GetSupplierBalance)
		SELECT D.SupplierID,
			Amount = SUM(CASE WHEN ISNULL(H.isOpening, 1) = 1 THEN D.Amount ELSE -D.Amount END)
		FROM SupplierOpeningHead H
		JOIN SupplierOpeningDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.[Date] = @OpDate
		GROUP BY D.SupplierID

		UNION ALL

		SELECT H.SupplierID, Amount = SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0))
		FROM PurchaseHead H
		JOIN #Customer C ON H.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.PaymentID IN (2, 5)
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.SupplierID

		UNION ALL

		SELECT D.SourceID, Amount = -SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
		FROM IncomeExpenseHead H
		JOIN IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.CashbookTypeID = 4
		  AND D.DetailAccountID = 26
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY D.SourceID

		UNION ALL

		SELECT H.ToSourceID, Amount = -SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.ToAcctID = 26 AND H.FromAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.ToSourceID

		UNION ALL

		SELECT H.FromSourceID, Amount = -SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.FromAcctID = 26 AND H.ToAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.FromSourceID

		UNION ALL

		SELECT H.ToSourceID, Amount = SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.ToAcctID = 26 AND H.FromAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.ToSourceID

		UNION ALL

		SELECT H.FromSourceID, Amount = -SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.FromAcctID = 26 AND H.ToAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.FromSourceID
	) opn
	JOIN Supplier C ON opn.SupplierID = C.ID
	GROUP BY C.Name

	/* ---------- Period movements (@FromDate .. @ToDate) ---------- */
	-- Purchase = net outstanding only (TotalAmount-PaidAmount).
	-- Do NOT also credit PaidAmount as Income/Expense (that broke O+P+Pay=C).
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, H.[Date], ISNULL(CAST(H.DocumentID AS nvarchar), H.AutoID), CC.Name, 'Purchase', '',
		Debit = SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0))
	FROM PurchaseHead H
	JOIN #Customer C ON H.SupplierID = C.c_id
	JOIN Supplier CC ON H.SupplierID = CC.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.PaymentID IN (2, 5)
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, CC.Name

	UNION ALL

	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), CC.Name, 'Income/Expense', A.Name,
		Credit = SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
	FROM IncomeExpenseHead H
	JOIN IncomeExpenseDetail D ON H.ID = D.RefID
	JOIN #Customer C ON D.SourceID = C.c_id
	JOIN Supplier CC ON D.SourceID = CC.ID
	JOIN AccountName A ON H.AccountID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.CashbookTypeID = 4
	  AND D.DetailAccountID = 26
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, CC.Name, A.Name

	UNION ALL

	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, 'Acct Transfer', A.Name,
		Credit = -SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.ToSourceID = C.c_id
	JOIN Supplier M ON H.ToSourceID = M.ID
	JOIN AccountName A ON H.ToAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.ToAcctID = 26 AND H.FromAcctID = 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL

	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, 'Acct Transfer', A.Name,
		Credit = -SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.FromSourceID = C.c_id
	JOIN Supplier M ON H.FromSourceID = M.ID
	JOIN AccountName A ON H.FromAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.FromAcctID = 26 AND H.ToAcctID = 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL

	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, 'Acct Transfer', A.Name,
		Debit = SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.ToSourceID = C.c_id
	JOIN Supplier M ON H.ToSourceID = M.ID
	JOIN AccountName A ON H.ToAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.ToAcctID = 26 AND H.FromAcctID <> 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL

	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, 'Acct Transfer', A.Name,
		Credit = -SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.FromSourceID = C.c_id
	JOIN Supplier M ON H.FromSourceID = M.ID
	JOIN AccountName A ON H.FromAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.FromAcctID = 26 AND H.ToAcctID <> 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	/* ---------- Closing: same @OpDate / filters as Opening, through @ToDate ---------- */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, @FromDate, DocumentID = '   ', LedgerName = C.Name, AccountName = 'Closing', AccountHeader = '', Amount = SUM(Amount)
	FROM
	(
		SELECT D.SupplierID,
			Amount = SUM(CASE WHEN ISNULL(H.isOpening, 1) = 1 THEN D.Amount ELSE -D.Amount END)
		FROM SupplierOpeningHead H
		JOIN SupplierOpeningDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.[Date] = @OpDate
		GROUP BY D.SupplierID

		UNION ALL

		SELECT H.SupplierID, Amount = SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0))
		FROM PurchaseHead H
		JOIN #Customer C ON H.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.PaymentID IN (2, 5)
		  AND H.[Date] BETWEEN @OpDate AND @ToDate
		GROUP BY H.SupplierID

		UNION ALL

		SELECT D.SourceID, Amount = -SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
		FROM IncomeExpenseHead H
		JOIN IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.CashbookTypeID = 4
		  AND D.DetailAccountID = 26
		  AND H.[Date] BETWEEN @OpDate AND @ToDate
		GROUP BY D.SourceID

		UNION ALL

		SELECT H.ToSourceID, Amount = -SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.ToAcctID = 26 AND H.FromAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @ToDate
		GROUP BY H.ToSourceID

		UNION ALL

		SELECT H.FromSourceID, Amount = -SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.FromAcctID = 26 AND H.ToAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @ToDate
		GROUP BY H.FromSourceID

		UNION ALL

		SELECT H.ToSourceID, Amount = SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.ToAcctID = 26 AND H.FromAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @ToDate
		GROUP BY H.ToSourceID

		UNION ALL

		SELECT H.FromSourceID, Amount = -SUM(H.Amount)
		FROM CustSupTransfer H
		JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND H.FromAcctID = 26 AND H.ToAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @ToDate
		GROUP BY H.FromSourceID
	) opn
	JOIN Supplier C ON opn.SupplierID = C.ID
	GROUP BY C.Name
END
GO

PRINT '[OK] CREATE OR ALTER dbo.SupplierOutstand — OpDate/Closing aligned with GetSupplierBalance filters';
GO
