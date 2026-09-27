/*======================================================================
  SB2 — ONE-SHOT fix: Supplier Outstand Summary + Balance Detail

  Screenshots after partial deploy showed:
    - Summary updated (Vicky/Lily identity mostly OK)
    - Detail STILL old SP (StockReceive lines, Opening 83,900 / 567,644)

  This script replaces BOTH procedures. Run entire file once on SB2.
  Verify section at end must print OK for both.

  Reference: dbo.GetSupplierBalance
    - OpDate = Max(SupplierOpeningHead.Date) <= @FromDate
    - isOpening sign flip
    - Purchase PaymentID IN (2,5), net TotalAmount-PaidAmount
    - IE CashbookTypeID=4 AND DetailAccountID=26
    - NO StockReceive in payable
    - NO PurchaseHead.PaidAmount as separate Payment row
======================================================================*/
USE [SB2];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ========== 1) SupplierOutstand ========== */
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

	IF LEN(ISNULL(@Supplier, N'')) > 0
		SET @Code = 'INSERT INTO #Customer SELECT ID FROM Supplier WHERE ID IN (' + @Supplier + ')'
	ELSE IF LEN(ISNULL(@Township, N'')) > 0
		SET @Code = 'INSERT INTO #Customer SELECT ID FROM Supplier WHERE TownshipID IN (' + @Township + ')'
	ELSE IF LEN(ISNULL(@Division, N'')) > 0
		SET @Code = 'INSERT INTO #Customer SELECT ID FROM Supplier C JOIN Township T ON C.TownshipID = T.ID WHERE DivisionId IN (' + @Division + ')'
	ELSE
		SET @Code = 'INSERT INTO #Customer SELECT ID FROM Supplier WHERE ISNULL(Deleted,0)<>1'

	EXEC (@Code)

	/* Opening */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, @FromDate, N'   ', C.Name, N'Opening', N'', SUM(Amount)
	FROM
	(
		SELECT D.SupplierID,
			Amount = SUM(CASE WHEN ISNULL(H.isOpening, 1) = 1 THEN D.Amount ELSE -D.Amount END)
		FROM SupplierOpeningHead H
		JOIN SupplierOpeningDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.[Date] = @OpDate
		GROUP BY D.SupplierID

		UNION ALL
		SELECT H.SupplierID, SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0))
		FROM PurchaseHead H
		JOIN #Customer C ON H.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.PaymentID IN (2, 5)
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.SupplierID

		UNION ALL
		SELECT D.SourceID, -SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
		FROM IncomeExpenseHead H
		JOIN IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 4
		  AND D.DetailAccountID = 26
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY D.SourceID

		UNION ALL
		SELECT H.ToSourceID, -SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.ToSourceID

		UNION ALL
		SELECT H.FromSourceID, -SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.FromSourceID

		UNION ALL
		SELECT H.ToSourceID, SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.ToSourceID

		UNION ALL
		SELECT H.FromSourceID, -SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.FromSourceID
	) opn
	JOIN Supplier C ON opn.SupplierID = C.ID
	GROUP BY C.Name

	/* Period — write Balance only (SupplierOutstandHistory pivots Balance) */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, H.[Date], ISNULL(CAST(H.DocumentID AS nvarchar(100)), H.AutoID), CC.Name, N'Purchase', N'',
		SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0))
	FROM PurchaseHead H
	JOIN #Customer C ON H.SupplierID = C.c_id
	JOIN Supplier CC ON H.SupplierID = CC.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.PaymentID IN (2, 5)
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, CC.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), CC.Name, N'Income/Expense', A.Name,
		SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
	FROM IncomeExpenseHead H
	JOIN IncomeExpenseDetail D ON H.ID = D.RefID
	JOIN #Customer C ON D.SourceID = C.c_id
	JOIN Supplier CC ON D.SourceID = CC.ID
	JOIN AccountName A ON H.AccountID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 4
	  AND D.DetailAccountID = 26
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, CC.Name, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, -SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.ToSourceID = C.c_id
	JOIN Supplier M ON H.ToSourceID = M.ID
	JOIN AccountName A ON H.ToAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID = 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, -SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.FromSourceID = C.c_id
	JOIN Supplier M ON H.FromSourceID = M.ID
	JOIN AccountName A ON H.FromAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID = 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.ToSourceID = C.c_id
	JOIN Supplier M ON H.ToSourceID = M.ID
	JOIN AccountName A ON H.ToAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID <> 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, -SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.FromSourceID = C.c_id
	JOIN Supplier M ON H.FromSourceID = M.ID
	JOIN AccountName A ON H.FromAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID <> 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	/* Closing = Opening + Purchase - Payment + AcctTransfer (exact identity) */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, @FromDate, N'   ', LedgerName, N'Closing', N'',
		SUM(CASE AccountName
			WHEN N'Opening' THEN ISNULL(Balance, 0)
			WHEN N'Purchase' THEN ISNULL(Balance, 0)
			WHEN N'PurchaseReturn' THEN -ISNULL(Balance, 0)
			WHEN N'Income/Expense' THEN -ISNULL(Balance, 0)
			WHEN N'Acct Transfer' THEN ISNULL(Balance, 0)
			ELSE 0 END)
	FROM GeneralLedgerDetail
	WHERE UserID = @UserID
	  AND AccountName IN (N'Opening', N'Purchase', N'PurchaseReturn', N'Income/Expense', N'Acct Transfer')
	GROUP BY LedgerName
END
GO

PRINT N'[OK] SupplierOutstand replaced';
GO

/* ========== 2) SupplierBalanceDetail ========== */
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

	IF LEN(ISNULL(@Supplier, N'')) > 0
		SET @Code = 'INSERT INTO #Customer SELECT ID FROM Supplier WHERE ID IN (' + @Supplier + ')'
	ELSE
		SET @Code = 'INSERT INTO #Customer SELECT ID FROM Supplier WHERE ISNULL(Deleted,0)<>1'

	EXEC (@Code)

	/* Opening — SAME formula as SupplierOutstand */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Balance)
	SELECT @UserID, @FromDate, N'   ', C.Name, N'Opening', N'', SUM(Amount)
	FROM
	(
		SELECT D.SupplierID,
			Amount = SUM(CASE WHEN ISNULL(H.isOpening, 1) = 1 THEN D.Amount ELSE -D.Amount END)
		FROM SupplierOpeningHead H
		JOIN SupplierOpeningDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.[Date] = @OpDate
		GROUP BY D.SupplierID

		UNION ALL
		SELECT H.SupplierID, SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0))
		FROM PurchaseHead H
		JOIN #Customer C ON H.SupplierID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.PaymentID IN (2, 5)
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.SupplierID

		UNION ALL
		SELECT D.SourceID, -SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
		FROM IncomeExpenseHead H
		JOIN IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN #Customer C ON D.SourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 4
		  AND D.DetailAccountID = 26
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY D.SourceID

		UNION ALL
		SELECT H.ToSourceID, -SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.ToSourceID

		UNION ALL
		SELECT H.FromSourceID, -SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID = 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.FromSourceID

		UNION ALL
		SELECT H.ToSourceID, SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.ToSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.ToSourceID

		UNION ALL
		SELECT H.FromSourceID, -SUM(H.Amount)
		FROM CustSupTransfer H JOIN #Customer C ON H.FromSourceID = C.c_id
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID <> 289
		  AND H.[Date] BETWEEN @OpDate AND @PreDate
		GROUP BY H.FromSourceID
	) opn
	JOIN Supplier C ON opn.SupplierID = C.ID
	GROUP BY C.Name

	/* Period — Debit=Increase, Credit=Decrease (Crystal FactoryBalanceDetail) */
	INSERT INTO GeneralLedgerDetail(UserID, Date, DocumentID, LedgerName, AccountName, AccountHeader, Debit, Credit)
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, ISNULL(H.Remark, N'Purchase'), N'',
		SUM(H.TotalAmount) - SUM(ISNULL(H.PaidAmount, 0)), 0
	FROM PurchaseHead H
	JOIN #Customer C ON H.SupplierID = C.c_id
	JOIN Supplier M ON H.SupplierID = M.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.PaymentID IN (2, 5)
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.DocumentID, H.AutoID, M.Name, H.Remark

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, D.Description, A.Name,
		0, SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
	FROM IncomeExpenseHead H
	JOIN IncomeExpenseDetail D ON H.ID = D.RefID
	JOIN #Customer C ON D.SourceID = C.c_id
	JOIN Supplier M ON D.SourceID = M.ID
	JOIN AccountName A ON H.AccountID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 4
	  AND D.DetailAccountID = 26
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.DocumentID, H.AutoID, M.Name, D.Description, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, 0, SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.ToSourceID = C.c_id
	JOIN Supplier M ON H.ToSourceID = M.ID
	JOIN AccountName A ON H.ToAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID = 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, 0, SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.FromSourceID = C.c_id
	JOIN Supplier M ON H.FromSourceID = M.ID
	JOIN AccountName A ON H.FromAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID = 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, SUM(H.Amount), 0
	FROM CustSupTransfer H
	JOIN #Customer C ON H.ToSourceID = C.c_id
	JOIN Supplier M ON H.ToSourceID = M.ID
	JOIN AccountName A ON H.ToAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 26 AND H.FromAcctID <> 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name

	UNION ALL
	SELECT @UserID, H.[Date], ISNULL(H.DocumentID, H.AutoID), M.Name, N'Acct Transfer', A.Name, 0, SUM(H.Amount)
	FROM CustSupTransfer H
	JOIN #Customer C ON H.FromSourceID = C.c_id
	JOIN Supplier M ON H.FromSourceID = M.ID
	JOIN AccountName A ON H.FromAcctID = A.ID
	WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 26 AND H.ToAcctID <> 289
	  AND H.[Date] BETWEEN @FromDate AND @ToDate
	GROUP BY H.[Date], H.AutoID, H.DocumentID, M.Name, A.Name
END
GO

PRINT N'[OK] SupplierBalanceDetail replaced';
GO

/* ========== 3) VERIFY — must show OK / no StockReceive ========== */
SELECT
	Obj = N'SupplierOutstand',
	HasStockReceive = CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierOutstand')) LIKE N'%StockReceive%' THEN N'FAIL still old' ELSE N'OK' END,
	HasPay25 = CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierOutstand')) LIKE N'%PaymentID IN (2, 5)%'
	                  OR OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierOutstand')) LIKE N'%PaymentID IN (2,5)%' THEN N'OK' ELSE N'FAIL' END,
	HasDetailAcct26 = CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierOutstand')) LIKE N'%DetailAccountID = 26%' THEN N'OK' ELSE N'FAIL' END
UNION ALL
SELECT
	N'SupplierBalanceDetail',
	CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierBalanceDetail')) LIKE N'%StockReceive%' THEN N'FAIL still old' ELSE N'OK' END,
	CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierBalanceDetail')) LIKE N'%PaymentID IN (2, 5)%'
	       OR OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierBalanceDetail')) LIKE N'%PaymentID IN (2,5)%' THEN N'OK' ELSE N'FAIL' END,
	CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SupplierBalanceDetail')) LIKE N'%DetailAccountID = 26%' THEN N'OK' ELSE N'FAIL' END;
GO

PRINT N'[DONE] Re-print Summary + Detail. Detail Opening must equal Summary Opening (same supplier).';
GO
