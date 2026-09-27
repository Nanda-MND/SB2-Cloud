/*======================================================================
  SB2 — Align dbo.SupplierBalanceDetail with GetSupplierBalance /
        SupplierOutstand (Summary Closing).

  Live SP issues vs dbo.GetSupplierBalance:
    1. Purchase used PaymentID = 2 only + StockReceived = 1
       (truth: PaymentID IN (2,5), no StockReceived filter).
    2. Opening/period included StockReceiveHead amounts — not in
       GetSupplierBalance / SupplierOutstand → Detail Opening drifts.
    3. Period posted Debit = TotalAmount-PaidAmount AND Credit = PaidAmount
       → net = TotalAmount - 2*PaidAmount (wrong). Use net Debit only;
       supplier payments come from IncomeExpense (CashbookTypeID = 4).
    4. IE missing DetailAccountID = 26.

  Run after SupplierOutstand_Fix_BalanceMismatch.sql (or together).
  SSMS → SB2 → execute entire script. No client rebuild.
======================================================================*/
USE [SB2];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[SupplierBalanceDetail]
(
	@FromDate Datetime,
	@ToDate Datetime,
	@Supplier nvarchar(1024) = null,
	@UserID int
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @OpDate Datetime, @PreDate Datetime

	SELECT @OpDate = MAX([Date])
	FROM SupplierOpeningHead
	WHERE ISNULL(Deleted, 0) <> 1
	  AND [Date] <= @FromDate

	IF @OpDate IS NULL
		SELECT @OpDate = MAX([Date])
		FROM SupplierOpeningHead
		WHERE ISNULL(Deleted, 0) <> 1

	IF @OpDate IS NULL
		SET @OpDate = CONVERT(datetime, '20250128')

	SET @PreDate = DATEADD(d, -1, @FromDate)

	DELETE FROM GeneralLedgerDetail WHERE UserID = @UserID

	DECLARE @Code nvarchar(max)
	CREATE TABLE #Customer (c_id int)

	IF LEN(@Supplier) > 0
		SET @Code = 'insert into #Customer select ID From Supplier Where ID in (' + @Supplier + ')'
	ELSE
		SET @Code = 'insert into #Customer select ID From Supplier Where isnull(Deleted,0)<>1 '

	EXEC (@Code)

	/* ---------- Opening (Balance column) — same filters as GetSupplierBalance ---------- */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, @FromDate, DocumentID = '   ', LedgerName = C.Name, AccountName = 'Opening', AccountHeader = '', Amount = SUM(Amount)
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

	/* ---------- Period (@FromDate..@ToDate): Debit=Increase, Credit=Decrease ---------- */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Debit, Credit)
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, H.Remark, '',
		Debit = SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0)),
		Credit = 0
	FROM PurchaseHead H
	JOIN #Customer C ON H.SupplierID = C.c_id
	JOIN Supplier M ON H.SupplierID = M.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.PaymentID IN (2, 5)
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.DocumentID, H.AutoID, M.Name, H.Remark

	UNION ALL

	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, D.Description, A.Name,
		Debit = 0,
		Credit = SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
	FROM IncomeExpenseHead H
	JOIN IncomeExpenseDetail D ON H.ID = D.RefID
	JOIN #Customer C ON D.SourceID = C.c_id
	JOIN Supplier M ON D.SourceID = M.ID
	JOIN AccountName A ON H.AccountID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.CashbookTypeID = 4
	  AND D.DetailAccountID = 26
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.DocumentID, H.AutoID, M.Name, D.Description, A.Name

	UNION ALL

	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, 'Acct Transfer', A.Name,
		Debit = 0, Credit = SUM(H.Amount)
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
		Debit = 0, Credit = SUM(H.Amount)
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
		Debit = SUM(H.Amount), Credit = 0
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
		Debit = 0, Credit = SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.FromSourceID = C.c_id
	JOIN Supplier M ON H.FromSourceID = M.ID
	JOIN AccountName A ON H.FromAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1
	  AND H.FromAcctID = 26 AND H.ToAcctID <> 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name
END
GO

PRINT '[OK] CREATE OR ALTER dbo.SupplierBalanceDetail — aligned with GetSupplierBalance';
GO
