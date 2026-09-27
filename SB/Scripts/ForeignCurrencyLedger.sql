/*======================================================================
  dbo.ForeignCurrencyLedger
  Ref: dbo.GeneralLedgerDetailReport (live SB2 paste 2026-09-18)

  Same GeneralLedgerDetail insert shape:
    Opening → LedgerName=A.Name, AccountName='Opening'
    Detail  → LedgerName=A.Name (group), AccountName=AA.Name (opposite),
              Remark=Description
    Closing → AccountName='Closing', DocumentID='zzzzz', Debit/Credit flipped

  Scope vs GL Detail:
    - AccountOpening + IncomeExpense CashbookTypeID IN (1, 4) only
    - Currency <> MMK (FC vouchers)
    - Amounts in FOREIGN CURRENCY (no * ExgRate)
    - @AccountID required (same as GL Where LedgerID = @AccountID)

  Params: @FromDate, @ToDate, @AccountID, @UserID
  Crystal: GeneralLedgerDetail.rpt
======================================================================*/
SET NOCOUNT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database (e.g. SB2) first.', 16, 1);
    RETURN;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ForeignCurrencyLedger]
(
    @FromDate  datetime,
    @ToDate    datetime,
    @AccountID int,
    @UserID    int
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OpDate datetime, @PreDate datetime, @MmkID int;

    SELECT TOP (1) @MmkID = C.ID
    FROM dbo.Currency C
    WHERE C.ID = 1
       OR UPPER(ISNULL(C.Name, N'')) IN (N'MMK', N'KS', N'KYAT', N'MYANMAR KYAT')
    ORDER BY CASE WHEN C.ID = 1 THEN 0 ELSE 1 END;
    IF @MmkID IS NULL SET @MmkID = 1;

    SELECT @OpDate = MAX([Date])
    FROM dbo.AccountOpeningHead
    WHERE ISNULL(Deleted, 0) <> 1
      AND [Date] <= @FromDate;
    SET @OpDate = ISNULL(@OpDate, '2025-04-06');
    SET @PreDate = DATEADD(DAY, -1, @FromDate);

    DELETE FROM dbo.GeneralLedgerDetail WHERE UserID = @UserID;

    /* ======================== OPENING ======================== */
    INSERT INTO dbo.GeneralLedgerDetail
        (UserID, [Date], DocumentID, Remark, LedgerName, AccountName, Debit, Credit, AccountHeader)
    SELECT
        @UserID,
        @FromDate,
        DocumentID = N'   ',
        Remark = N'',
        LedgerName = A.Name,
        AccountName = N'Opening',
        Debit  = IIF(SUM(opn.Debit) > 0, SUM(opn.Debit), 0),
        Credit = IIF(SUM(opn.Debit) > 0, 0, ABS(SUM(opn.Debit))),
        AccountHeader = N''
    FROM
    (
        /* Account opening */
        SELECT LedgerAccountID = D.AccountID,
               Debit = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
        FROM dbo.AccountOpeningHead H
        INNER JOIN dbo.AccountOpeningDetail D ON H.ID = D.RefID
        WHERE H.[Date] = @OpDate
          AND ISNULL(H.Deleted, 0) <> 1
          AND D.AccountID = @AccountID
        GROUP BY D.AccountID

        UNION ALL
        /* IE type 1 — header = ledger (FC, no ExgRate) */
        SELECT LedgerAccountID = H.AccountID,
               Debit = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 1
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @PreDate
          AND H.AccountID = @AccountID
        GROUP BY H.AccountID

        UNION ALL
        /* IE type 1 — detail = ledger */
        SELECT LedgerAccountID = D.DetailAccountID,
               Debit = SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 1
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @PreDate
          AND D.DetailAccountID = @AccountID
        GROUP BY D.DetailAccountID

        UNION ALL
        /* Supplier Payment type 4 — header = ledger (FC) */
        SELECT LedgerAccountID = H.AccountID,
               Debit = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        INNER JOIN dbo.Supplier S ON D.SourceID = S.ID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 4
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @PreDate
          AND H.AccountID = @AccountID
        GROUP BY H.AccountID

        UNION ALL
        /* Supplier Payment type 4 — detail = ledger */
        SELECT LedgerAccountID = D.DetailAccountID,
               Debit = SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        INNER JOIN dbo.Supplier S ON D.SourceID = S.ID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 4
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @PreDate
          AND D.DetailAccountID = @AccountID
        GROUP BY D.DetailAccountID
    ) opn
    INNER JOIN dbo.AccountName A ON opn.LedgerAccountID = A.ID
    WHERE opn.LedgerAccountID = @AccountID
    GROUP BY A.Name;

    /* ======================== PERIOD DETAIL ======================== */
    INSERT INTO dbo.GeneralLedgerDetail
        (UserID, [Date], DocumentID, Remark, LedgerName, AccountName, Debit, Credit, AccountHeader)
    SELECT
        @UserID,
        tmp.[Date],
        DocumentID = ISNULL(NULLIF(tmp.DocumentID, N''), tmp.AutoID),
        Remark = tmp.Description,
        LedgerName = A.Name,     -- group header = filter account
        AccountName = AA.Name,   -- detail Account = opposite
        Debit = SUM(tmp.Debit),
        Credit = SUM(tmp.Credit),
        AccountHeader = N''
    FROM
    (
        /* IE 1 — filter account is HEADER */
        SELECT
            H.[Date],
            AutoID = ISNULL(H.AutoID, N''),
            DocumentID = ISNULL(H.DocumentID, N''),
            LedgerID = H.AccountID,
            OppositeID = D.DetailAccountID,
            Description = ISNULL(D.Description, N''),
            Debit = SUM(ISNULL(D.Debit, 0)),
            Credit = SUM(ISNULL(D.Credit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 1
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @FromDate AND @ToDate
          AND H.AccountID = @AccountID
        GROUP BY H.[Date], H.AutoID, H.DocumentID, H.AccountID, D.DetailAccountID, D.Description

        UNION ALL
        /* IE 1 — filter account is DETAIL */
        SELECT
            H.[Date],
            AutoID = ISNULL(H.AutoID, N''),
            DocumentID = ISNULL(H.DocumentID, N''),
            LedgerID = D.DetailAccountID,
            OppositeID = H.AccountID,
            Description = ISNULL(D.Description, N''),
            Debit = SUM(ISNULL(D.Credit, 0)),
            Credit = SUM(ISNULL(D.Debit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 1
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @FromDate AND @ToDate
          AND D.DetailAccountID = @AccountID
        GROUP BY H.[Date], H.AutoID, H.DocumentID, D.DetailAccountID, H.AccountID, D.Description

        UNION ALL
        /* Supplier Payment 4 — filter account is HEADER */
        SELECT
            H.[Date],
            AutoID = ISNULL(H.AutoID, N''),
            DocumentID = ISNULL(H.DocumentID, N''),
            LedgerID = H.AccountID,
            OppositeID = D.DetailAccountID,
            Description = ISNULL(D.Description, N'') + N'  ' + ISNULL(S.Name, N''),
            Debit = SUM(ISNULL(D.Debit, 0)),
            Credit = SUM(ISNULL(D.Credit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        INNER JOIN dbo.Supplier S ON D.SourceID = S.ID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 4
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @FromDate AND @ToDate
          AND H.AccountID = @AccountID
        GROUP BY H.[Date], H.AutoID, H.DocumentID, H.AccountID, D.DetailAccountID, D.Description, S.Name

        UNION ALL
        /* Supplier Payment 4 — filter account is DETAIL */
        SELECT
            H.[Date],
            AutoID = ISNULL(H.AutoID, N''),
            DocumentID = ISNULL(H.DocumentID, N''),
            LedgerID = D.DetailAccountID,
            OppositeID = H.AccountID,
            Description = ISNULL(D.Description, N'') + N'  ' + ISNULL(S.Name, N''),
            Debit = SUM(ISNULL(D.Credit, 0)),
            Credit = SUM(ISNULL(D.Debit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        INNER JOIN dbo.Supplier S ON D.SourceID = S.ID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 4
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @FromDate AND @ToDate
          AND D.DetailAccountID = @AccountID
        GROUP BY H.[Date], H.AutoID, H.DocumentID, D.DetailAccountID, H.AccountID, D.Description, S.Name
    ) tmp
    INNER JOIN dbo.AccountName A ON tmp.LedgerID = A.ID
    INNER JOIN dbo.AccountName AA ON tmp.OppositeID = AA.ID
    WHERE tmp.LedgerID = @AccountID
    GROUP BY tmp.[Date], tmp.AutoID, tmp.DocumentID, tmp.Description, A.Name, AA.Name;

    /* ======================== CLOSING ======================== */
    INSERT INTO dbo.GeneralLedgerDetail
        (UserID, [Date], DocumentID, Remark, LedgerName, AccountName, Debit, Credit, AccountHeader)
    SELECT
        @UserID,
        @ToDate,
        DocumentID = N'zzzzz',
        Remark = N'',
        LedgerName = A.Name,
        AccountName = N'Closing',
        Debit  = IIF(SUM(opn.Debit) > 0, 0, ABS(SUM(opn.Debit))),
        Credit = IIF(SUM(opn.Debit) > 0, SUM(opn.Debit), 0),
        AccountHeader = N''
    FROM
    (
        SELECT LedgerAccountID = D.AccountID,
               Debit = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
        FROM dbo.AccountOpeningHead H
        INNER JOIN dbo.AccountOpeningDetail D ON H.ID = D.RefID
        WHERE H.[Date] = @OpDate
          AND ISNULL(H.Deleted, 0) <> 1
          AND D.AccountID = @AccountID
        GROUP BY D.AccountID

        UNION ALL
        SELECT LedgerAccountID = H.AccountID,
               Debit = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 1
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @ToDate
          AND H.AccountID = @AccountID
        GROUP BY H.AccountID

        UNION ALL
        SELECT LedgerAccountID = D.DetailAccountID,
               Debit = SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 1
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @ToDate
          AND D.DetailAccountID = @AccountID
        GROUP BY D.DetailAccountID

        UNION ALL
        SELECT LedgerAccountID = H.AccountID,
               Debit = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        INNER JOIN dbo.Supplier S ON D.SourceID = S.ID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 4
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @ToDate
          AND H.AccountID = @AccountID
        GROUP BY H.AccountID

        UNION ALL
        SELECT LedgerAccountID = D.DetailAccountID,
               Debit = SUM(ISNULL(D.Credit, 0) - ISNULL(D.Debit, 0))
        FROM dbo.IncomeExpenseHead H
        INNER JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
        INNER JOIN dbo.Supplier S ON D.SourceID = S.ID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CashbookTypeID = 4
          AND H.CurrencyID <> @MmkID
          AND H.[Date] BETWEEN @OpDate AND @ToDate
          AND D.DetailAccountID = @AccountID
        GROUP BY D.DetailAccountID
    ) opn
    INNER JOIN dbo.AccountName A ON opn.LedgerAccountID = A.ID
    WHERE opn.LedgerAccountID = @AccountID
    GROUP BY A.Name;
END
GO

PRINT N'[OK] CREATE OR ALTER dbo.ForeignCurrencyLedger';
GO

SELECT
    ObjectName = N'dbo.ForeignCurrencyLedger',
    Status = CASE WHEN OBJECT_ID(N'dbo.ForeignCurrencyLedger', N'P') IS NOT NULL THEN N'OK' ELSE N'MISSING' END;
GO
