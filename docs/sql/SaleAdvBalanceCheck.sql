-- Sale Advance/Balance DATE-level audit (NEW objects only — does not alter existing SPs/functions).
-- Internal replay still uses DocumentID order within day (same as voucher version).
-- Output: one row per Customer + Date.
--
-- Rollback to voucher rows:
--   1) Deploy docs/sql/SaleAdvBalanceCheck_ByVoucher.sql  (if not already)
--   2) Deploy docs/sql/SaleAdvBalanceCheck_RollbackToVoucher.sql
--
-- Deploy: sqlcmd -i SaleAdvBalanceCheck.sql
-- Fill: EXEC dbo.SaleAdvBalanceCheck @FromDate, @ToDate, @Division, @Township, @Customer, @UserID
-- Read: SELECT * FROM dbo.SaleAdvBalanceAudit WHERE UserID = @UserID ORDER BY CustomerName, Date

IF OBJECT_ID(N'dbo.SaleAdvBalanceAudit', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SaleAdvBalanceAudit
    (
        UserID           int            NOT NULL,
        CustomerID       int            NOT NULL,
        CustomerName     nvarchar(200)  NULL,
        SaleID           int            NOT NULL,
        [Date]           datetime       NULL,
        AutoID           nvarchar(50)   NULL,
        DocumentID       nvarchar(50)   NULL,
        LocationID       int            NULL,
        LocationName     nvarchar(100)  NULL,
        PaymentID        int            NULL,
        PaymentName      nvarchar(100)  NULL,
        Amount           money          NULL,
        TotalAmount      money          NULL,
        PaidAmount       money          NULL,
        AdvAmount        money          NULL,
        StoredAdv        money          NULL,
        ExpectedAdv      money          NULL,
        DiffAdv          money          NULL,
        StoredBal        money          NULL,
        ExpectedBal      money          NULL,
        DiffBal          money          NULL,
        IsMismatch       bit            NOT NULL CONSTRAINT DF_SaleAdvBalanceAudit_IsMismatch DEFAULT (0),
        IsNegative       bit            NOT NULL CONSTRAINT DF_SaleAdvBalanceAudit_IsNegative DEFAULT (0),
        IsFirstMismatch  bit            NOT NULL CONSTRAINT DF_SaleAdvBalanceAudit_IsFirstMismatch DEFAULT (0),
        Flag             nvarchar(40)   NULL
    );

    CREATE CLUSTERED INDEX IX_SaleAdvBalanceAudit_User
        ON dbo.SaleAdvBalanceAudit (UserID, CustomerName, [Date], SaleID);
END
GO

CREATE OR ALTER PROCEDURE dbo.SaleAdvBalanceCheck
(
    @FromDate  datetime,
    @ToDate    datetime,
    @Division  nvarchar(1024) = NULL,
    @Township  nvarchar(1024) = NULL,
    @Customer  nvarchar(1024) = NULL,
    @UserID    int,
    @OnlyIssue bit = 0   -- 1 = mismatch / negative only
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BalOpDate datetime;
    DECLARE @AdvOpDate datetime;
    DECLARE @Code nvarchar(max);

    -- Same anchors as GetCustomerBalance / GetCustomerAdvance
    SELECT @BalOpDate = MAX(dbo.CastDate([Date]))
    FROM dbo.CustomerOpeningHead
    WHERE ISNULL(Deleted, 0) <> 1
      AND ISNULL(isOpening, 0) = 1;

    SELECT @AdvOpDate = MAX(dbo.CastDate([Date]))
    FROM dbo.CustomerOpeningHead
    WHERE ISNULL(Deleted, 0) <> 1
      AND ISNULL(isOpening, 0) = 0;

    IF @AdvOpDate IS NULL
        SET @AdvOpDate = '2025-01-28';

    IF @BalOpDate IS NULL
        SET @BalOpDate = @AdvOpDate;

    SET @BalOpDate = dbo.CastDate(@BalOpDate);
    SET @AdvOpDate = dbo.CastDate(@AdvOpDate);

    DELETE FROM dbo.SaleAdvBalanceAudit WHERE UserID = @UserID;

    CREATE TABLE #Customer (c_id int PRIMARY KEY);

    IF LEN(@Customer) > 0
        SET @Code = N'INSERT INTO #Customer SELECT ID FROM Customer WHERE ID IN (' + @Customer + N')';
    ELSE IF LEN(@Township) > 0
        SET @Code = N'INSERT INTO #Customer SELECT ID FROM Customer WHERE TownshipID IN (' + @Township + N')';
    ELSE IF LEN(@Division) > 0
        SET @Code = N'INSERT INTO #Customer SELECT ID FROM Customer C JOIN Township T ON C.TownshipID = T.ID WHERE DivisionId IN (' + @Division + N')';
    ELSE
        SET @Code = N'INSERT INTO #Customer SELECT ID FROM Customer WHERE ISNULL(Deleted,0)<>1';

    EXEC (@Code);

    ------------------------------------------------------------------
    -- Opening amounts (latest opening head ID on the global max date)
    ------------------------------------------------------------------
    CREATE TABLE #OpenBal
    (
        CustomerID int PRIMARY KEY,
        OpenBal    money NOT NULL
    );

    CREATE TABLE #OpenAdv
    (
        CustomerID int PRIMARY KEY,
        OpenAdv    money NOT NULL
    );

    ;WITH BalHead AS
    (
        SELECT
            D.CustomerID,
            HeadID = MAX(H.ID)
        FROM dbo.CustomerOpeningHead H
        JOIN dbo.CustomerOpeningDetail D ON H.ID = D.RefID
        JOIN #Customer C ON D.CustomerID = C.c_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ISNULL(H.isOpening, 0) = 1
          AND dbo.CastDate(H.[Date]) = @BalOpDate
        GROUP BY D.CustomerID
    )
    INSERT INTO #OpenBal (CustomerID, OpenBal)
    SELECT
        B.CustomerID,
        OpenBal = ISNULL(SUM(D.Amount), 0)
    FROM BalHead B
    JOIN dbo.CustomerOpeningDetail D
      ON D.RefID = B.HeadID
     AND D.CustomerID = B.CustomerID
    GROUP BY B.CustomerID;

    ;WITH AdvHead AS
    (
        SELECT
            D.CustomerID,
            HeadID = MAX(H.ID)
        FROM dbo.CustomerOpeningHead H
        JOIN dbo.CustomerOpeningDetail D ON H.ID = D.RefID
        JOIN #Customer C ON D.CustomerID = C.c_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ISNULL(H.isOpening, 0) = 0
          AND dbo.CastDate(H.[Date]) = @AdvOpDate
        GROUP BY D.CustomerID
    )
    INSERT INTO #OpenAdv (CustomerID, OpenAdv)
    SELECT
        A.CustomerID,
        OpenAdv = ISNULL(SUM(D.Amount), 0)
    FROM AdvHead A
    JOIN dbo.CustomerOpeningDetail D
      ON D.RefID = A.HeadID
     AND D.CustomerID = A.CustomerID
    GROUP BY A.CustomerID;

    ------------------------------------------------------------------
    -- Event stream (mirrors GetCustomerAdvance / GetCustomerBalance)
    -- Same-day order: Sale / SaleReturn BEFORE Customer Receive,
    -- so advance received on D appears on sales dated D+1 (not earlier sales on D).
    -- Seq: SaleOrder=1, SaleReturn=2, Sale=3, IE Adv=4, IE Bal=5, Transfer=6
    ------------------------------------------------------------------
    CREATE TABLE #Evt
    (
        CustomerID   int            NOT NULL,
        EvtDate      datetime       NOT NULL,
        Seq          tinyint        NOT NULL,
        RefID        int            NOT NULL,
        SortDoc      int            NOT NULL,  -- Sale: numeric DocumentID (else SaleID); others: RefID
        IsSaleCheck  bit            NOT NULL,
        AdvDelta     money          NOT NULL,
        BalDelta     money          NOT NULL,
        -- Sale snapshot fields (only when IsSaleCheck = 1)
        AutoID       nvarchar(50)   NULL,
        DocumentID   nvarchar(50)   NULL,
        LocationID   int            NULL,
        PaymentID    int            NULL,
        Amount       money          NULL,
        TotalAmount  money          NULL,
        PaidAmount   money          NULL,
        AdvAmount    money          NULL,
        StoredAdv    money          NULL,
        StoredBal    money          NULL
    );

    -- SaleHead (same-day order = DocumentID, not SaleHead.ID)
    INSERT INTO #Evt
    (
        CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck,
        AdvDelta, BalDelta,
        AutoID, DocumentID, LocationID, PaymentID,
        Amount, TotalAmount, PaidAmount, AdvAmount, StoredAdv, StoredBal
    )
    SELECT
        H.CustomerID,
        dbo.CastDate(H.[Date]),
        CAST(3 AS tinyint),
        H.ID,
        -- DocumentID may be nvarchar (e.g. zn-150); never CAST raw into int SortDoc
        SortDoc = ISNULL(TRY_CONVERT(int, H.DocumentID), H.ID),
        CAST(1 AS bit),
        AdvDelta = CASE
            WHEN H.PaymentID IN (2, 5) AND dbo.CastDate(H.[Date]) >= @AdvOpDate
                THEN -ISNULL(H.AdvAmount, 0)
            ELSE CAST(0 AS money)
        END,
        BalDelta = CASE
            WHEN H.PaymentID IN (2, 5) AND dbo.CastDate(H.[Date]) >= @BalOpDate
                THEN ISNULL(H.TotalAmount, 0) - ISNULL(H.PaidAmount, 0) - ISNULL(H.AdvAmount, 0)
            ELSE CAST(0 AS money)
        END,
        H.AutoID,
        CAST(H.DocumentID AS nvarchar(50)),
        H.LocationID,
        H.PaymentID,
        H.Amount,
        H.TotalAmount,
        H.PaidAmount,
        H.AdvAmount,
        StoredAdv = ISNULL(H.AdvBalance, 0),
        StoredBal = ISNULL(H.Balance, 0)
    FROM dbo.SaleHead H
    JOIN #Customer C ON H.CustomerID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND dbo.CastDate(H.[Date]) >= CASE WHEN @AdvOpDate < @BalOpDate THEN @AdvOpDate ELSE @BalOpDate END;

    -- SaleReturnHead (balance only; advance line is commented out in GetCustomerAdvance)
    INSERT INTO #Evt
    (
        CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck,
        AdvDelta, BalDelta
    )
    SELECT
        H.CustomerID,
        dbo.CastDate(H.[Date]),
        CAST(2 AS tinyint),
        H.ID,
        SortDoc = ISNULL(TRY_CONVERT(int, H.DocumentID), H.ID),
        CAST(0 AS bit),
        CAST(0 AS money),
        BalDelta = CASE
            WHEN H.PaymentID IN (2, 5) AND dbo.CastDate(H.[Date]) >= @BalOpDate
                THEN -(ISNULL(H.TotalAmount, 0) - ISNULL(H.PaidAmount, 0))
            ELSE CAST(0 AS money)
        END
    FROM dbo.SaleReturnHead H
    JOIN #Customer C ON H.CustomerID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.PaymentID IN (2, 5)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    -- SaleOrderHead → Advance + (same cutoff as GetCustomerAdvance)
    INSERT INTO #Evt
    (
        CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck,
        AdvDelta, BalDelta
    )
    SELECT
        H.CustomerID,
        dbo.CastDate(H.[Date]),
        CAST(1 AS tinyint),
        H.ID,
        SortDoc = ISNULL(TRY_CONVERT(int, H.DocumentID), H.ID),
        CAST(0 AS bit),
        AdvDelta = ISNULL(H.AdvAmount, 0),
        CAST(0 AS money)
    FROM dbo.SaleOrderHead H
    JOIN #Customer C ON H.CustomerID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.PaymentID NOT IN (2, 5)
      AND dbo.CastDate(H.[Date]) >= @AdvOpDate
      AND dbo.CastDate(H.[Date]) > '2026-04-11';

    -- Income/Expense → Advance account 1490
    INSERT INTO #Evt
    (
        CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck,
        AdvDelta, BalDelta
    )
    SELECT
        D.SourceID,
        dbo.CastDate(H.[Date]),
        CAST(4 AS tinyint),
        H.ID,
        SortDoc = H.ID,
        CAST(0 AS bit),
        AdvDelta = SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0)),
        CAST(0 AS money)
    FROM dbo.IncomeExpenseHead H
    JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
    JOIN #Customer C ON D.SourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.CashbookTypeID = 3
      AND D.DetailAccountID = 1490
      AND dbo.CastDate(H.[Date]) >= @AdvOpDate
    GROUP BY D.SourceID, dbo.CastDate(H.[Date]), H.ID;

    -- Income/Expense → Customer receivable 289
    INSERT INTO #Evt
    (
        CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck,
        AdvDelta, BalDelta
    )
    SELECT
        D.SourceID,
        dbo.CastDate(H.[Date]),
        CAST(5 AS tinyint),
        H.ID,
        SortDoc = H.ID,
        CAST(0 AS bit),
        CAST(0 AS money),
        BalDelta = -SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
    FROM dbo.IncomeExpenseHead H
    JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
    JOIN #Customer C ON D.SourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.CashbookTypeID = 3
      AND D.DetailAccountID = 289
      AND dbo.CastDate(H.[Date]) >= @BalOpDate
    GROUP BY D.SourceID, dbo.CastDate(H.[Date]), H.ID;

    -- CustSupTransfer → Balance only (same 4 branches as GetCustomerBalance)
    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.ToSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, -ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H
    JOIN #Customer C ON H.ToSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.ToAcctID = 289 AND H.FromAcctID IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.FromSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, -ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H
    JOIN #Customer C ON H.FromSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.FromAcctID = 289 AND H.ToAcctID IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.ToSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H
    JOIN #Customer C ON H.ToSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.ToAcctID = 289 AND H.FromAcctID NOT IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.FromSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, -ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H
    JOIN #Customer C ON H.FromSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.FromAcctID = 289 AND H.ToAcctID NOT IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    ------------------------------------------------------------------
    -- Running Expected = Opening + sum(deltas before this event)
    -- Then collapse to one row per Customer + Date
    ------------------------------------------------------------------
    ;WITH Ordered AS
    (
        SELECT
            E.*,
            OpenAdv = ISNULL(OA.OpenAdv, 0),
            OpenBal = ISNULL(OB.OpenBal, 0)
        FROM #Evt E
        LEFT JOIN #OpenAdv OA ON OA.CustomerID = E.CustomerID
        LEFT JOIN #OpenBal OB ON OB.CustomerID = E.CustomerID
    ),
    Running AS
    (
        SELECT
            O.*,
            ExpectedAdv =
                O.OpenAdv
                + ISNULL(SUM(O.AdvDelta) OVER
                  (
                      PARTITION BY O.CustomerID
                      ORDER BY O.EvtDate, O.Seq, O.SortDoc, O.RefID
                      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                  ), 0),
            ExpectedBal =
                O.OpenBal
                + ISNULL(SUM(O.BalDelta) OVER
                  (
                      PARTITION BY O.CustomerID
                      ORDER BY O.EvtDate, O.Seq, O.SortDoc, O.RefID
                      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                  ), 0)
        FROM Ordered O
    ),
    SaleRows AS
    (
        SELECT
            R.*,
            VoucherMismatch = CASE
                WHEN ISNULL(R.StoredAdv, 0) <> R.ExpectedAdv
                  OR ISNULL(R.StoredBal, 0) <> R.ExpectedBal
                THEN CAST(1 AS bit) ELSE CAST(0 AS bit)
            END,
            VoucherNegative = CASE
                WHEN R.ExpectedAdv < 0
                  OR R.ExpectedBal < 0
                  OR ISNULL(R.StoredAdv, 0) < 0
                  OR ISNULL(R.StoredBal, 0) < 0
                THEN CAST(1 AS bit) ELSE CAST(0 AS bit)
            END
        FROM Running R
        WHERE R.IsSaleCheck = 1
          AND R.EvtDate BETWEEN dbo.CastDate(@FromDate) AND dbo.CastDate(@ToDate)
    ),
    DayAgg AS
    (
        SELECT
            S.*,
            rnDay = ROW_NUMBER() OVER
            (
                PARTITION BY S.CustomerID, S.EvtDate
                ORDER BY S.SortDoc, S.RefID
            ),
            SaleCount = COUNT(*) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            DayAmount = SUM(ISNULL(S.Amount, 0)) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            DayAdvAmount = SUM(ISNULL(S.AdvAmount, 0)) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            DayTotalAmount = SUM(ISNULL(S.TotalAmount, 0)) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            DayPaidAmount = SUM(ISNULL(S.PaidAmount, 0)) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            MinDoc = MIN(S.SortDoc) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            MaxDoc = MAX(S.SortDoc) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            DayMismatch = MAX(CAST(S.VoucherMismatch AS int)) OVER (PARTITION BY S.CustomerID, S.EvtDate),
            DayNegative = MAX(CAST(S.VoucherNegative AS int)) OVER (PARTITION BY S.CustomerID, S.EvtDate)
        FROM SaleRows S
    ),
    DayRows AS
    (
        -- Representative snapshot = first DocumentID sale of the day
        SELECT
            D.*,
            DiffAdv = ISNULL(D.StoredAdv, 0) - D.ExpectedAdv,
            DiffBal = ISNULL(D.StoredBal, 0) - D.ExpectedBal,
            IsMismatch = CAST(CASE WHEN D.DayMismatch = 1 THEN 1 ELSE 0 END AS bit),
            IsNegative = CAST(CASE WHEN D.DayNegative = 1 THEN 1 ELSE 0 END AS bit)
        FROM DayAgg D
        WHERE D.rnDay = 1
    ),
    Ranked AS
    (
        SELECT
            D.*,
            IsFirstMismatch = CASE
                WHEN D.IsMismatch = 1
                 AND ROW_NUMBER() OVER
                     (
                         PARTITION BY D.CustomerID, CASE WHEN D.IsMismatch = 1 THEN 1 ELSE 0 END
                         ORDER BY D.EvtDate
                     ) = 1
                THEN CAST(1 AS bit)
                ELSE CAST(0 AS bit)
            END
        FROM DayRows D
    )
    INSERT INTO dbo.SaleAdvBalanceAudit
    (
        UserID, CustomerID, CustomerName, SaleID, [Date], AutoID, DocumentID,
        LocationID, LocationName, PaymentID, PaymentName,
        Amount, TotalAmount, PaidAmount, AdvAmount,
        StoredAdv, ExpectedAdv, DiffAdv,
        StoredBal, ExpectedBal, DiffBal,
        IsMismatch, IsNegative, IsFirstMismatch, Flag
    )
    SELECT
        @UserID,
        R.CustomerID,
        CU.Name,
        SaleID = R.SaleCount,                          -- sale count that day
        R.EvtDate,
        AutoID = R.AutoID,                             -- first AutoID of day
        DocumentID = CASE
            WHEN R.MinDoc = R.MaxDoc THEN CAST(R.MinDoc AS nvarchar(50))
            ELSE CAST(R.MinDoc AS nvarchar(20)) + N'-' + CAST(R.MaxDoc AS nvarchar(20))
        END,
        R.LocationID,
        L.Short,
        R.PaymentID,
        PaymentName = N'Day (' + CAST(R.SaleCount AS nvarchar(10)) + N')',
        Amount = R.DayAmount,
        TotalAmount = R.DayTotalAmount,
        PaidAmount = R.DayPaidAmount,
        AdvAmount = R.DayAdvAmount,
        R.StoredAdv,
        R.ExpectedAdv,
        R.DiffAdv,
        R.StoredBal,
        R.ExpectedBal,
        R.DiffBal,
        R.IsMismatch,
        R.IsNegative,
        R.IsFirstMismatch,
        Flag = CASE
            WHEN R.IsFirstMismatch = 1 THEN N'FirstMismatch'
            WHEN R.IsMismatch = 1 AND R.IsNegative = 1 THEN N'Mismatch+Negative'
            WHEN R.IsMismatch = 1 THEN N'Mismatch'
            WHEN R.IsNegative = 1 THEN N'Negative'
            ELSE N'OK'
        END
    FROM Ranked R
    JOIN dbo.Customer CU ON CU.ID = R.CustomerID
    LEFT JOIN dbo.Location L ON L.ID = R.LocationID
    WHERE (@OnlyIssue = 0 OR R.IsMismatch = 1 OR R.IsNegative = 1);

    -- Results are read from dbo.SaleAdvBalanceAudit (UserID = @UserID).
END
GO
