/*
  GeneralLedgerSummary — Period movement totals per account (AcctCode, AcctName, Dr, Cr).

  Rules (agreed):
    - Ref: GeneralLedgerDetailReport period unions (Opening/Closing excluded)
    - One row per account: Total Dr + Total Cr (both sides)
    - Zero movement (Dr=0 and Cr=0) excluded
    - Filters: @Account / @AcctGroup via dbo.fn_AccountInFilter
    - Inserts into GeneralLedgerDetail for existing GeneralLedgerSummary.rpt:
        LedgerName = AcctGroup.Short + '-' + AcctGroup.Name (Group Header #1)
        Short / DocumentID = AcctCode (detail + Group #2)
        AccountName = AccountName.Name (detail "Account")
        Debit / Credit = period totals
        GroupID = AcctGroup.ID
        AccountHeader = same as LedgerName

  Prerequisites: docs/sql/AccountFilter_Helper.sql (dbo.fn_AccountInFilter)

  Run on: SB1 (Local; Cloud if report runs there).
*/

USE [SB1];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[GeneralLedgerSummary]
(
	@FromDate Datetime,
	@ToDate Datetime,
	@Account nvarchar(max) = N'',
	@AcctGroup nvarchar(max) = N'',
	@UserID int
)
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM dbo.GeneralLedgerDetail WHERE UserID = @UserID;

	;WITH Movement AS
	(
		-- Income / Expense (cashbook) — bank/cash side
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(D.Debit, 0) * H.ExgRate),
			Credit = SUM(ISNULL(D.Credit, 0) * H.ExgRate)
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 1
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		GROUP BY H.AccountID

		UNION ALL
		-- Income / Expense — detail account side (income)
		SELECT LedgerID = D.DetailAccountID,
			Debit = SUM(ISNULL(D.Credit, 0)),
			Credit = SUM(ISNULL(D.Debit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 1
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(D.DetailAccountID, @Account, @AcctGroup) = 1
		GROUP BY D.DetailAccountID

		UNION ALL
		-- Journal
		SELECT LedgerID = D.DetailAccountID,
			Debit = SUM(ISNULL(D.Debit, 0)),
			Credit = SUM(ISNULL(D.Credit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 2
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(D.DetailAccountID, @Account, @AcctGroup) = 1
		GROUP BY D.DetailAccountID

		UNION ALL
		-- Customer receipt — bank/cash
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Discount, 0) + ISNULL(D.Surplus, 0)),
			Credit = SUM(ISNULL(D.Credit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN dbo.Customer C ON D.SourceID = C.ID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 3
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		GROUP BY H.AccountID

		UNION ALL
		-- Customer receipt — AR side
		SELECT LedgerID = D.DetailAccountID,
			Debit = SUM(ISNULL(D.Credit, 0)),
			Credit = SUM(ISNULL(D.Debit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN dbo.Customer C ON D.SourceID = C.ID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 3
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(D.DetailAccountID, @Account, @AcctGroup) = 1
		GROUP BY D.DetailAccountID

		UNION ALL
		-- Supplier payment — bank (non-1012 FX)
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(D.Debit, 0) * H.ExgRate),
			Credit = SUM(ISNULL(D.Credit, 0) * H.ExgRate)
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN dbo.Supplier S ON D.SourceID = S.ID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 4
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		  AND H.AccountID IN (SELECT ID FROM dbo.AccountName WHERE GroupID <> 1012)
		GROUP BY H.AccountID

		UNION ALL
		-- Supplier payment — bank (group 1012)
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(D.Debit, 0)),
			Credit = SUM(ISNULL(D.Credit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN dbo.Supplier S ON D.SourceID = S.ID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 4
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		  AND H.AccountID IN (SELECT ID FROM dbo.AccountName WHERE GroupID = 1012)
		GROUP BY H.AccountID

		UNION ALL
		-- Supplier payment — AP side
		SELECT LedgerID = D.DetailAccountID,
			Debit = SUM(ISNULL(D.Credit, 0)),
			Credit = SUM(ISNULL(D.Debit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN dbo.Supplier S ON D.SourceID = S.ID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 4
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(D.DetailAccountID, @Account, @AcctGroup) = 1
		GROUP BY D.DetailAccountID

		UNION ALL
		-- Manufacturer — bank
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(D.Debit, 0)),
			Credit = SUM(ISNULL(D.Credit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN dbo.Manufacturer S ON D.SourceID = S.ID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 5
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		GROUP BY H.AccountID

		UNION ALL
		-- Manufacturer — detail
		SELECT LedgerID = D.DetailAccountID,
			Debit = SUM(ISNULL(D.Credit, 0)),
			Credit = SUM(ISNULL(D.Debit, 0))
		FROM dbo.IncomeExpenseHead H
		JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
		JOIN dbo.Manufacturer S ON D.SourceID = S.ID
		WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 5
		  AND H.Date BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(D.DetailAccountID, @Account, @AcctGroup) = 1
		GROUP BY D.DetailAccountID

		UNION ALL
		-- Sale discount account 113
		SELECT LedgerID = 113,
			Debit = SUM(ISNULL(H.Discount, 0)),
			Credit = CAST(0 AS decimal(18, 4))
		FROM dbo.SaleHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND ISNULL(H.Discount, 0) > 0
		  AND dbo.fn_AccountInFilter(113, @Account, @AcctGroup) = 1

		UNION ALL
		-- Sale → bank/cash (legacy date cut)
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(H.Amount, 0) - ISNULL(H.Discount, 0) + ISNULL(H.TaxAmount, 0)),
			Credit = CAST(0 AS decimal(18, 4))
		FROM dbo.SaleHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND ISNULL(H.PaymentID, 1) NOT IN (1, 2, 5)
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND dbo.CastDate(H.Date) <= '2025-03-11'
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		GROUP BY H.AccountID

		UNION ALL
		-- Sale → bank/cash (after cut, non-cash payments)
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(H.Amount, 0) - ISNULL(H.Discount, 0) + ISNULL(H.TaxAmount, 0)),
			Credit = CAST(0 AS decimal(18, 4))
		FROM dbo.SaleHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND ISNULL(H.PaymentID, 1) NOT IN (1, 2, 5)
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND dbo.CastDate(H.Date) > '2025-03-11'
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		GROUP BY H.AccountID

		UNION ALL
		-- Cash sales → 288
		SELECT LedgerID = 288,
			Debit = SUM(ISNULL(H.Amount, 0) - ISNULL(H.Discount, 0) + ISNULL(H.TaxAmount, 0)),
			Credit = CAST(0 AS decimal(18, 4))
		FROM dbo.SaleHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND ISNULL(H.PaymentID, 1) = 1
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND dbo.CastDate(H.Date) > '2025-03-11'
		  AND dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1

		UNION ALL
		-- Sale return → bank/cash
		SELECT LedgerID = H.AccountID,
			Debit = CAST(0 AS decimal(18, 4)),
			Credit = SUM(H.TotalAmount)
		FROM dbo.SaleReturnHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND ISNULL(H.PaymentID, 1) NOT IN (1, 2, 5)
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		GROUP BY H.AccountID

		UNION ALL
		-- Cash sale return → 288
		SELECT LedgerID = 288,
			Debit = CAST(0 AS decimal(18, 4)),
			Credit = SUM(H.TotalAmount)
		FROM dbo.SaleReturnHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND ISNULL(H.PaymentID, 1) = 1
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND dbo.fn_AccountInFilter(288, @Account, @AcctGroup) = 1

		UNION ALL
		-- Sale order advance → customer advance acct 1490 (credit)
		SELECT LedgerID = 1490,
			Debit = CAST(0 AS decimal(18, 4)),
			Credit = SUM(ISNULL(H.AdvAmount, 0))
		FROM dbo.SaleOrderHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND ISNULL(H.PaymentID, 1) NOT IN (2, 5)
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND dbo.CastDate(H.Date) > '2026-04-11'
		  AND dbo.fn_AccountInFilter(1490, @Account, @AcctGroup) = 1

		UNION ALL
		-- Sale order advance → bank/cash (debit)
		SELECT LedgerID = H.AccountID,
			Debit = SUM(ISNULL(H.AdvAmount, 0)),
			Credit = CAST(0 AS decimal(18, 4))
		FROM dbo.SaleOrderHead H
		WHERE ISNULL(H.Deleted, 0) <> 1
		  AND ISNULL(H.PaymentID, 1) NOT IN (2, 5)
		  AND dbo.CastDate(H.Date) BETWEEN @FromDate AND @ToDate
		  AND dbo.CastDate(H.Date) > '2026-04-11'
		  AND dbo.fn_AccountInFilter(H.AccountID, @Account, @AcctGroup) = 1
		GROUP BY H.AccountID
	),
	Totals AS
	(
		SELECT
			M.LedgerID,
			Dr = SUM(ISNULL(M.Debit, 0)),
			Cr = SUM(ISNULL(M.Credit, 0))
		FROM Movement M
		GROUP BY M.LedgerID
		HAVING SUM(ISNULL(M.Debit, 0)) <> 0 OR SUM(ISNULL(M.Credit, 0)) <> 0
	)
	INSERT INTO dbo.GeneralLedgerDetail
	(
		UserID, Date, DocumentID, Remark,
		LedgerName, AccountName, Debit, Credit,
		AccountHeader, Short, GroupID
	)
	SELECT
		@UserID,
		@FromDate,
		ISNULL(A.Short, N''),   -- DocumentID = AcctCode
		N'',
		ISNULL(AG.Short, N'') + N'-' + ISNULL(AG.Name, N''), -- LedgerName = AcctGroup (Group #1)
		A.Name,                 -- AccountName = account name (Details)
		T.Dr,
		T.Cr,
		ISNULL(AG.Short, N'') + N'-' + ISNULL(AG.Name, N''), -- AccountHeader
		ISNULL(A.Short, N''),   -- Short → AcctCode
		AG.ID
	FROM Totals T
	JOIN dbo.AccountName A ON T.LedgerID = A.ID
	JOIN dbo.AcctGroup AG ON A.GroupID = AG.ID
	WHERE dbo.fn_AccountInFilter(T.LedgerID, @Account, @AcctGroup) = 1
	ORDER BY AG.Short, AG.Name, A.Short, A.Name;

END
GO

PRINT 'dbo.GeneralLedgerSummary created.';
GO
