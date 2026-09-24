-- ROLLBACK SOURCE: voucher-by-voucher version (DocumentID order within day).
-- Kept as dbo.SaleAdvBalanceCheck_ByVoucher so it can run side-by-side,
-- and as the restore source for SaleAdvBalanceCheck_RollbackToVoucher.sql.
--
-- Deploy: sqlcmd -i SaleAdvBalanceCheck_ByVoucher.sql
-- Run:    EXEC dbo.SaleAdvBalanceCheck_ByVoucher @FromDate, @ToDate, ..., @UserID

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

CREATE OR ALTER PROCEDURE dbo.SaleAdvBalanceCheck_ByVoucher
(
    @FromDate  datetime,
    @ToDate    datetime,
    @Division  nvarchar(1024) = NULL,
    @Township  nvarchar(1024) = NULL,
    @Customer  nvarchar(1024) = NULL,
    @UserID    int,
    @OnlyIssue bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BalOpDate datetime;
    DECLARE @AdvOpDate datetime;
    DECLARE @Code nvarchar(max);

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

    CREATE TABLE #OpenBal (CustomerID int PRIMARY KEY, OpenBal money NOT NULL);
    CREATE TABLE #OpenAdv (CustomerID int PRIMARY KEY, OpenAdv money NOT NULL);

    ;WITH BalHead AS
    (
        SELECT D.CustomerID, HeadID = MAX(H.ID)
        FROM dbo.CustomerOpeningHead H
        JOIN dbo.CustomerOpeningDetail D ON H.ID = D.RefID
        JOIN #Customer C ON D.CustomerID = C.c_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ISNULL(H.isOpening, 0) = 1
          AND dbo.CastDate(H.[Date]) = @BalOpDate
        GROUP BY D.CustomerID
    )
    INSERT INTO #OpenBal (CustomerID, OpenBal)
    SELECT B.CustomerID, ISNULL(SUM(D.Amount), 0)
    FROM BalHead B
    JOIN dbo.CustomerOpeningDetail D ON D.RefID = B.HeadID AND D.CustomerID = B.CustomerID
    GROUP BY B.CustomerID;

    ;WITH AdvHead AS
    (
        SELECT D.CustomerID, HeadID = MAX(H.ID)
        FROM dbo.CustomerOpeningHead H
        JOIN dbo.CustomerOpeningDetail D ON H.ID = D.RefID
        JOIN #Customer C ON D.CustomerID = C.c_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ISNULL(H.isOpening, 0) = 0
          AND dbo.CastDate(H.[Date]) = @AdvOpDate
        GROUP BY D.CustomerID
    )
    INSERT INTO #OpenAdv (CustomerID, OpenAdv)
    SELECT A.CustomerID, ISNULL(SUM(D.Amount), 0)
    FROM AdvHead A
    JOIN dbo.CustomerOpeningDetail D ON D.RefID = A.HeadID AND D.CustomerID = A.CustomerID
    GROUP BY A.CustomerID;

    -- Seq: SaleOrder=1, SaleReturn=2, Sale=3, IE Adv=4, IE Bal=5, Transfer=6
    CREATE TABLE #Evt
    (
        CustomerID   int            NOT NULL,
        EvtDate      datetime       NOT NULL,
        Seq          tinyint        NOT NULL,
        RefID        int            NOT NULL,
        SortDoc      int            NOT NULL,
        IsSaleCheck  bit            NOT NULL,
        AdvDelta     money          NOT NULL,
        BalDelta     money          NOT NULL,
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

    INSERT INTO #Evt
    (
        CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck,
        AdvDelta, BalDelta,
        AutoID, DocumentID, LocationID, PaymentID,
        Amount, TotalAmount, PaidAmount, AdvAmount, StoredAdv, StoredBal
    )
    SELECT
        H.CustomerID, dbo.CastDate(H.[Date]), CAST(3 AS tinyint), H.ID,
        ISNULL(H.DocumentID, H.ID), CAST(1 AS bit),
        CASE WHEN H.PaymentID IN (2, 5) AND dbo.CastDate(H.[Date]) >= @AdvOpDate
             THEN -ISNULL(H.AdvAmount, 0) ELSE CAST(0 AS money) END,
        CASE WHEN H.PaymentID IN (2, 5) AND dbo.CastDate(H.[Date]) >= @BalOpDate
             THEN ISNULL(H.TotalAmount, 0) - ISNULL(H.PaidAmount, 0) - ISNULL(H.AdvAmount, 0)
             ELSE CAST(0 AS money) END,
        H.AutoID, CAST(H.DocumentID AS nvarchar(50)), H.LocationID, H.PaymentID,
        H.Amount, H.TotalAmount, H.PaidAmount, H.AdvAmount,
        ISNULL(H.AdvBalance, 0), ISNULL(H.Balance, 0)
    FROM dbo.SaleHead H
    JOIN #Customer C ON H.CustomerID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND dbo.CastDate(H.[Date]) >= CASE WHEN @AdvOpDate < @BalOpDate THEN @AdvOpDate ELSE @BalOpDate END;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.CustomerID, dbo.CastDate(H.[Date]), 2, H.ID, ISNULL(H.DocumentID, H.ID), 0, 0,
        CASE WHEN H.PaymentID IN (2, 5) AND dbo.CastDate(H.[Date]) >= @BalOpDate
             THEN -(ISNULL(H.TotalAmount, 0) - ISNULL(H.PaidAmount, 0)) ELSE 0 END
    FROM dbo.SaleReturnHead H
    JOIN #Customer C ON H.CustomerID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.PaymentID IN (2, 5)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.CustomerID, dbo.CastDate(H.[Date]), 1, H.ID, ISNULL(H.DocumentID, H.ID), 0,
        ISNULL(H.AdvAmount, 0), 0
    FROM dbo.SaleOrderHead H
    JOIN #Customer C ON H.CustomerID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.PaymentID NOT IN (2, 5)
      AND dbo.CastDate(H.[Date]) >= @AdvOpDate
      AND dbo.CastDate(H.[Date]) > '2026-04-11';

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT D.SourceID, dbo.CastDate(H.[Date]), 4, H.ID, H.ID, 0,
        SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0)), 0
    FROM dbo.IncomeExpenseHead H
    JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
    JOIN #Customer C ON D.SourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 3 AND D.DetailAccountID = 1490
      AND dbo.CastDate(H.[Date]) >= @AdvOpDate
    GROUP BY D.SourceID, dbo.CastDate(H.[Date]), H.ID;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT D.SourceID, dbo.CastDate(H.[Date]), 5, H.ID, H.ID, 0, 0,
        -SUM(ISNULL(D.Debit, 0) - ISNULL(D.Credit, 0))
    FROM dbo.IncomeExpenseHead H
    JOIN dbo.IncomeExpenseDetail D ON H.ID = D.RefID
    JOIN #Customer C ON D.SourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 3 AND D.DetailAccountID = 289
      AND dbo.CastDate(H.[Date]) >= @BalOpDate
    GROUP BY D.SourceID, dbo.CastDate(H.[Date]), H.ID;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.ToSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, -ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H JOIN #Customer C ON H.ToSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 289 AND H.FromAcctID IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.FromSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, -ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H JOIN #Customer C ON H.FromSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 289 AND H.ToAcctID IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.ToSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H JOIN #Customer C ON H.ToSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID = 289 AND H.FromAcctID NOT IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    INSERT INTO #Evt (CustomerID, EvtDate, Seq, RefID, SortDoc, IsSaleCheck, AdvDelta, BalDelta)
    SELECT H.FromSourceID, dbo.CastDate(H.[Date]), 6, H.ID, H.ID, 0, 0, -ISNULL(H.Amount, 0)
    FROM dbo.CustSupTransfer H JOIN #Customer C ON H.FromSourceID = C.c_id
    WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID = 289 AND H.ToAcctID NOT IN (26, 1452)
      AND dbo.CastDate(H.[Date]) >= @BalOpDate;

    ;WITH Ordered AS
    (
        SELECT E.*, OpenAdv = ISNULL(OA.OpenAdv, 0), OpenBal = ISNULL(OB.OpenBal, 0)
        FROM #Evt E
        LEFT JOIN #OpenAdv OA ON OA.CustomerID = E.CustomerID
        LEFT JOIN #OpenBal OB ON OB.CustomerID = E.CustomerID
    ),
    Running AS
    (
        SELECT O.*,
            ExpectedAdv = O.OpenAdv + ISNULL(SUM(O.AdvDelta) OVER (
                PARTITION BY O.CustomerID ORDER BY O.EvtDate, O.Seq, O.SortDoc, O.RefID
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0),
            ExpectedBal = O.OpenBal + ISNULL(SUM(O.BalDelta) OVER (
                PARTITION BY O.CustomerID ORDER BY O.EvtDate, O.Seq, O.SortDoc, O.RefID
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)
        FROM Ordered O
    ),
    SaleRows AS
    (
        SELECT R.*,
            DiffAdv = ISNULL(R.StoredAdv, 0) - R.ExpectedAdv,
            DiffBal = ISNULL(R.StoredBal, 0) - R.ExpectedBal,
            IsMismatch = CASE WHEN ISNULL(R.StoredAdv, 0) <> R.ExpectedAdv
                                OR ISNULL(R.StoredBal, 0) <> R.ExpectedBal
                              THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END,
            IsNegative = CASE WHEN R.ExpectedAdv < 0 OR R.ExpectedBal < 0
                                OR ISNULL(R.StoredAdv, 0) < 0 OR ISNULL(R.StoredBal, 0) < 0
                              THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
        FROM Running R
        WHERE R.IsSaleCheck = 1
          AND R.EvtDate BETWEEN dbo.CastDate(@FromDate) AND dbo.CastDate(@ToDate)
    ),
    Ranked AS
    (
        SELECT S.*,
            IsFirstMismatch = CASE
                WHEN S.IsMismatch = 1 AND ROW_NUMBER() OVER (
                    PARTITION BY S.CustomerID, CASE WHEN S.IsMismatch = 1 THEN 1 ELSE 0 END
                    ORDER BY S.EvtDate, S.Seq, S.SortDoc, S.RefID) = 1
                THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
        FROM SaleRows S
    )
    INSERT INTO dbo.SaleAdvBalanceAudit
    (
        UserID, CustomerID, CustomerName, SaleID, [Date], AutoID, DocumentID,
        LocationID, LocationName, PaymentID, PaymentName,
        Amount, TotalAmount, PaidAmount, AdvAmount,
        StoredAdv, ExpectedAdv, DiffAdv, StoredBal, ExpectedBal, DiffBal,
        IsMismatch, IsNegative, IsFirstMismatch, Flag
    )
    SELECT
        @UserID, R.CustomerID, CU.Name, R.RefID, R.EvtDate, R.AutoID, R.DocumentID,
        R.LocationID, L.Short, R.PaymentID, P.Name,
        R.Amount, R.TotalAmount, R.PaidAmount, R.AdvAmount,
        R.StoredAdv, R.ExpectedAdv, R.DiffAdv, R.StoredBal, R.ExpectedBal, R.DiffBal,
        R.IsMismatch, R.IsNegative, R.IsFirstMismatch,
        CASE
            WHEN R.IsFirstMismatch = 1 THEN N'FirstMismatch'
            WHEN R.IsMismatch = 1 AND R.IsNegative = 1 THEN N'Mismatch+Negative'
            WHEN R.IsMismatch = 1 THEN N'Mismatch'
            WHEN R.IsNegative = 1 THEN N'Negative'
            ELSE N'OK'
        END
    FROM Ranked R
    JOIN dbo.Customer CU ON CU.ID = R.CustomerID
    LEFT JOIN dbo.Location L ON L.ID = R.LocationID
    LEFT JOIN dbo.PaymentType P ON P.ID = R.PaymentID
    WHERE (@OnlyIssue = 0 OR R.IsMismatch = 1 OR R.IsNegative = 1);

    SELECT CustomerID, CustomerName, [Date], DocumentID, AutoID, PaymentName,
           Amount, AdvAmount, StoredAdv, ExpectedAdv, DiffAdv,
           StoredBal, ExpectedBal, DiffBal, Flag, IsFirstMismatch
    FROM dbo.SaleAdvBalanceAudit
    WHERE UserID = @UserID
    ORDER BY CustomerName, [Date], TRY_CAST(DocumentID AS int), SaleID;
END
GO
