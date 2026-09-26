/*======================================================================
  Balance Sheet SP (ReportName 1097) — PNL-style output for PNL.rpt
  Preview query (same shape as PNL):
    select LedgerName, Name = ISNULL(AG.Name, GL.AccountName), Balance, CodeID
    from GeneralLedgerDetail GL Left Join AcctGroup AG on GL.GroupID = AG.ID
    where UserID = @UserID

  CodeID 1 = Assets
  CodeID 2 = Liabilities
  CodeID 3 = Owners' Equity (+ Net Profit)
  CodeID 4 = Total Assets
  CodeID 5 = Total Liabilities & Equity

  Run on client ERP DB (not master). Idempotent CREATE OR ALTER.
======================================================================*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database first.', 16, 1);
    SET NOEXEC ON;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[BalanceSheet]
(
    @UserID   INT,
    @FromDate DATETIME,
    @ToDate   DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Asset MONEY, @Liability MONEY, @Equity MONEY, @NetProfit MONEY;

    EXEC dbo.TrialBalance @FromDate = @FromDate, @ToDate = @ToDate, @UserID = @UserID;

    IF OBJECT_ID(N'tempdb..#BSClosing') IS NOT NULL DROP TABLE #BSClosing;

    SELECT
        LedgerName,
        MainGroupID = GroupID,
        Balance = ISNULL(Debit, 0) - ISNULL(Credit, 0)
    INTO #BSClosing
    FROM dbo.GeneralLedgerDetail
    WHERE UserID = @UserID
      AND AccountName = N'5. Closing'
      AND GroupID IN (1, 2, 3);

    SELECT @NetProfit = SUM(ISNULL(Credit, 0) - ISNULL(Debit, 0))
    FROM dbo.GeneralLedgerDetail
    WHERE UserID = @UserID
      AND AccountName = N'5. Closing'
      AND GroupID IN (4, 5, 6, 7);

    SET @NetProfit = ISNULL(@NetProfit, 0);

    DELETE FROM dbo.GeneralLedgerDetail WHERE UserID = @UserID;

    /* CodeID 1 — Assets (debit-normal) */
    INSERT INTO dbo.GeneralLedgerDetail (CodeID, LedgerName, AccountName, GroupID, Balance, UserID)
    SELECT
        1,
        N'Assets',
        C.LedgerName,
        ISNULL(AN.GroupID, 0),
        C.Balance,
        @UserID
    FROM #BSClosing C
    OUTER APPLY
    (
        SELECT TOP (1) AN0.GroupID
        FROM dbo.AccountName AN0
        WHERE AN0.Name = C.LedgerName AND ISNULL(AN0.Deleted, 0) <> 1
        ORDER BY AN0.ID
    ) AN
    WHERE C.MainGroupID = 1
      AND ISNULL(C.Balance, 0) <> 0;

    /* CodeID 2 — Liabilities (credit-normal → positive display) */
    INSERT INTO dbo.GeneralLedgerDetail (CodeID, LedgerName, AccountName, GroupID, Balance, UserID)
    SELECT
        2,
        N'Liabilities',
        C.LedgerName,
        ISNULL(AN.GroupID, 0),
        -C.Balance,
        @UserID
    FROM #BSClosing C
    OUTER APPLY
    (
        SELECT TOP (1) AN0.GroupID
        FROM dbo.AccountName AN0
        WHERE AN0.Name = C.LedgerName AND ISNULL(AN0.Deleted, 0) <> 1
        ORDER BY AN0.ID
    ) AN
    WHERE C.MainGroupID = 2
      AND ISNULL(C.Balance, 0) <> 0;

    /* CodeID 3 — Equity (credit-normal) */
    INSERT INTO dbo.GeneralLedgerDetail (CodeID, LedgerName, AccountName, GroupID, Balance, UserID)
    SELECT
        3,
        N'Owners'' Equity',
        C.LedgerName,
        ISNULL(AN.GroupID, 0),
        -C.Balance,
        @UserID
    FROM #BSClosing C
    OUTER APPLY
    (
        SELECT TOP (1) AN0.GroupID
        FROM dbo.AccountName AN0
        WHERE AN0.Name = C.LedgerName AND ISNULL(AN0.Deleted, 0) <> 1
        ORDER BY AN0.ID
    ) AN
    WHERE C.MainGroupID = 3
      AND ISNULL(C.Balance, 0) <> 0;

    IF @NetProfit <> 0
        INSERT INTO dbo.GeneralLedgerDetail (CodeID, LedgerName, AccountName, GroupID, Balance, UserID)
        VALUES (3, N'Owners'' Equity', N'Net Profit', 0, @NetProfit, @UserID);

    SELECT @Asset = SUM(Balance) FROM dbo.GeneralLedgerDetail WHERE UserID = @UserID AND CodeID = 1;
    SELECT @Liability = SUM(Balance) FROM dbo.GeneralLedgerDetail WHERE UserID = @UserID AND CodeID = 2;
    SELECT @Equity = SUM(Balance) FROM dbo.GeneralLedgerDetail WHERE UserID = @UserID AND CodeID = 3;

    INSERT INTO dbo.GeneralLedgerDetail (CodeID, LedgerName, AccountName, GroupID, Balance, UserID)
    VALUES
        (4, N'Total Assets', N'Total Assets', 0, ISNULL(@Asset, 0), @UserID),
        (5, N'Total Liabilities & Equity', N'Total Liabilities & Equity', 0, ISNULL(@Liability, 0) + ISNULL(@Equity, 0), @UserID);

    DROP TABLE #BSClosing;
END
GO

PRINT 'OK: BalanceSheet SP';
GO
