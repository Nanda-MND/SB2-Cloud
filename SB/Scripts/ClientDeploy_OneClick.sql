/*======================================================================
  SB2 Client Deploy -- one-click (idempotent)
  Tested against local restore: [SB2] on this machine (2026-08-14)

  HOW TO RUN
    1. In SSMS, select the client ERP database (name does not have to be SB2)
    2. Execute this entire file
    3. Check Messages for [OK]/[SKIP] and the Verification result set

  This script syncs DB objects the current app needs.
  C# only fix (Balance Enquiry money to int) requires a rebuilt EXE.

  Local SB2 audit (client latest restore):
    PurchaseReturnHead.StockChange ........ already EXISTS
    ListviewItem PurReturn ................ already 10 rows
    SaleProfitFIFO table + SaleProfitFIFO_SP  already EXISTS (same logic)
    GP_AVG ................................ OLD (AVG(Price)) -- this script updates
    ReportName 1146 ....................... not registered (removed by request)
======================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT 'Database: ' + DB_NAME();
PRINT 'Server:   ' + @@SERVERNAME;
PRINT 'Started:  ' + CONVERT(varchar(19), GETDATE(), 120);
PRINT '';

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database first. Do not run on master.', 16, 1);
    SET NOEXEC ON;
END
GO

/*======================================================================
  1) Purchase Return  -- StockChange on PurchaseReturnHead
======================================================================*/
IF COL_LENGTH(N'dbo.PurchaseReturnHead', N'StockChange') IS NULL
BEGIN
    ALTER TABLE dbo.PurchaseReturnHead
        ADD StockChange BIT NOT NULL
            CONSTRAINT DF_PurchaseReturnHead_StockChange DEFAULT (1);
    PRINT '[OK] Added PurchaseReturnHead.StockChange';
END
ELSE
    PRINT '[SKIP] PurchaseReturnHead.StockChange already exists';
GO

IF COL_LENGTH(N'dbo.PurchaseReturnHead', N'StockChange') IS NOT NULL
BEGIN
    UPDATE dbo.PurchaseReturnHead
    SET StockChange = 1
    WHERE StockChange IS NULL OR StockChange = 0;
    PRINT '[OK] PurchaseReturnHead.StockChange ensured = 1 (rows=' + CAST(@@ROWCOUNT AS varchar(20)) + ')';
END
GO

/*======================================================================
  2) Purchase Return  -- ListviewItem (MenuName = PurReturn)
     Client ListviewItem has no Sr column.
======================================================================*/
IF NOT EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'PurReturn')
BEGIN
    INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    SELECT
        N'PurReturn',
        CASE ColumnName WHEN N'Customer' THEN N'Supplier' ELSE ColumnName END,
        ColumnWidth,
        CASE ColumnHeader WHEN N'Customer' THEN N'Supplier' ELSE ColumnHeader END
    FROM dbo.ListviewItem
    WHERE MenuName = N'SaleReturn';

    PRINT '[OK] Inserted ListviewItem PurReturn from SaleReturn (rows=' + CAST(@@ROWCOUNT AS varchar(20)) + ')';
END
ELSE
    PRINT '[SKIP] ListviewItem PurReturn already exists';

IF NOT EXISTS (
    SELECT 1 FROM dbo.ListviewItem
    WHERE MenuName = N'PurReturn' AND ColumnName = N'Payment'
)
BEGIN
    INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    VALUES (N'PurReturn', N'Payment', 100, N'Payment');
    PRINT '[OK] Added ListviewItem PurReturn.Payment';
END
ELSE
    PRINT '[SKIP] ListviewItem PurReturn.Payment already exists';
GO

/*======================================================================
  3) SaleProfitFIFO table + SaleProfitFIFO_SP (CREATE OR ALTER)
======================================================================*/

-- SaleProfitFIFO_SP: GP margin via FIFO (aligned with StockValuationFIFO_Ground).
-- Ground min-unit rules:
--   Qty   = SUM(dbo.GetMinQty(CodeID, UnitID, Qty))
--   Price = MAX(dbo.GetMinPurPrice(CodeID, UnitID, Price))
-- SalePrice (min) = SaleAmount / MinQty; FIFOCost = lot GetMinPurPrice
-- Qty = FIFO take qty (GetMinQty); CostAmount = TakeQty * FIFOCost
-- Margin % = (SalePrice - FIFOCost) / FIFOCost * 100
-- Report: frm_Preview case 1146

IF OBJECT_ID(N'dbo.SaleProfitFIFO', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SaleProfitFIFO
    (
        ID            INT IDENTITY(1, 1) NOT NULL,
        UserID        INT           NOT NULL,
        SaleHeadID    INT           NOT NULL,
        SaleDetailID  INT           NOT NULL,
        Sr            INT           NULL,
        [Date]        DATETIME      NOT NULL,
        AutoID        NVARCHAR(50)  NULL,
        DocumentID    NVARCHAR(50)  NULL,
        CustomerID    INT           NULL,
        Customer      NVARCHAR(255) NULL,
        LocationID    INT           NULL,
        Location      NVARCHAR(50)  NULL,
        CodeID        INT           NOT NULL,
        BrandID       INT           NULL,
        Qty           FLOAT         NOT NULL,
        SalePrice     MONEY         NOT NULL,
        SaleAmount    MONEY         NOT NULL,
        FIFOCost      MONEY         NOT NULL,
        CostAmount    MONEY         NOT NULL,
        Profit        MONEY         NOT NULL,
        CONSTRAINT PK_SaleProfitFIFO PRIMARY KEY CLUSTERED (ID)
    );

    CREATE INDEX IX_SaleProfitFIFO_UserID ON dbo.SaleProfitFIFO (UserID);
END
GO

CREATE OR ALTER PROC [dbo].[SaleProfitFIFO_SP]
(
    @UserID    INT            = NULL,
    @FDate     DATETIME       = NULL,
    @TDate     DATETIME       = NULL,
    @Code      NVARCHAR(1024) = NULL,
    @GroupID   INT            = NULL,
    @TypeID    INT            = NULL,
    @Location  NVARCHAR(1024) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PreDate DATETIME = DATEADD(DAY, -1, @FDate);
    DECLARE @MaxOpnDate DATETIME;
    DECLARE @CodeFilter NVARCHAR(1024) = ISNULL(@Code, N'');
    -- Ground treats ISNULL(GroupID,0)<>0 as filter; -1 / 0 = all
    DECLARE @GroupFilter INT = CASE WHEN ISNULL(@GroupID, 0) IN (0, -1) THEN NULL ELSE @GroupID END;
    DECLARE @TypeFilter INT = CASE WHEN ISNULL(@TypeID, 0) IN (0, -1) THEN NULL ELSE @TypeID END;
    DECLARE @LocFilter NVARCHAR(1024) = ISNULL(@Location, N'');
    DECLARE @SQL NVARCHAR(MAX);

    SELECT @MaxOpnDate = MAX(Date)
    FROM StockOpeningHead
    WHERE ISNULL(Deleted, 0) <> 1
      AND Date <= @FDate;

    IF @MaxOpnDate IS NULL
        SET @MaxOpnDate = '2025-01-28';

    -------------------------------------------------------------------------
    -- Filters (same as Ground)
    -------------------------------------------------------------------------
    CREATE TABLE #Code (c_id INT PRIMARY KEY);

    IF LEN(@CodeFilter) > 0
    BEGIN
        IF CHARINDEX(N'%', @CodeFilter) > 0 OR CHARINDEX(N'_', @CodeFilter) > 0
            INSERT INTO #Code SELECT ID FROM Stock WHERE Short LIKE @CodeFilter;
        ELSE
            INSERT INTO #Code SELECT ID FROM Stock WHERE Short LIKE N'%' + @CodeFilter + N'%';
    END
    ELSE IF @GroupFilter IS NOT NULL
        INSERT INTO #Code SELECT ID FROM Stock WHERE GroupID = @GroupFilter;
    ELSE IF @TypeFilter IS NOT NULL
        INSERT INTO #Code
        SELECT ID FROM Stock
        WHERE GroupID IN (SELECT ID FROM StockGroup WHERE TypeID = @TypeFilter);
    ELSE
        INSERT INTO #Code SELECT ID FROM Stock WHERE ISNULL(Deleted, 0) <> 1;

    CREATE TABLE #Loc (l_id INT PRIMARY KEY);

    IF LEN(@LocFilter) > 0
        SET @SQL = N'INSERT INTO #Loc SELECT ID FROM Location WHERE ID IN (' + @LocFilter + N')';
    ELSE
        SET @SQL = N'INSERT INTO #Loc SELECT ID FROM Location WHERE ISNULL(Deleted,0)<>1';

    EXEC (@SQL);

    -------------------------------------------------------------------------
    -- IN layers = Ground #_Purchase (real Date; Transfer excluded)
    -------------------------------------------------------------------------
    CREATE TABLE #_Purchase
    (
        LotID   INT IDENTITY(1, 1) NOT NULL,
        [Date]  DATETIME NOT NULL,
        Code    INT      NOT NULL,
        Brand   INT      NOT NULL,
        Price   MONEY    NOT NULL,
        PurQty  FLOAT    NOT NULL
    );

    INSERT INTO #_Purchase ([Date], Code, Brand, Price, PurQty)
    SELECT [Date], CodeID, BrandID, Price, SUM(Qty)
    FROM
    (
        SELECT
            [Date] = H.Date,
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            Price = MAX(dbo.GetMinPurPrice(D.CodeID, D.UnitID, ISNULL(D.Price, 0))),
            Qty = SUM(dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty))
        FROM StockOpeningHead H
        JOIN StockOpeningDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.Date = @MaxOpnDate
        GROUP BY H.Date, D.CodeID, D.BrandID

        UNION ALL

        SELECT
            [Date] = H.Date,
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            Price = MAX(dbo.GetMinPurPrice(D.CodeID, D.UnitID, ISNULL(D.Price, 0))),
            Qty = SUM(dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty))
        FROM PurchaseHead H
        JOIN PurchaseDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ISNULL(H.StockReceived, 0) = 1
          AND H.Date BETWEEN @MaxOpnDate AND @TDate
        GROUP BY H.Date, H.CurrencyID, D.CodeID, D.BrandID

        UNION ALL

        SELECT
            [Date] = H.Date,
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            Price = MAX(dbo.GetMinPurPrice(
                        D.CodeID, D.UnitID,
                        ISNULL(D.Price, 0) + ISNULL(D.CostCon, 0) + ISNULL(D.CostTran, 0))),
            Qty = SUM(dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty))
        FROM StockReceiveHead H
        JOIN StockReceiveDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.Date BETWEEN @MaxOpnDate AND @TDate
        GROUP BY H.Date, D.CodeID, D.BrandID, D.UnitID, D.PurPrice, D.CostCon, D.CostTran

        UNION ALL

        SELECT
            [Date] = H.Date,
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            Price = MAX(dbo.GetMinPurPrice(D.CodeID, D.UnitID, ISNULL(D.Price, 0))),
            Qty = SUM(dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty))
        FROM SaleReturnHead H
        JOIN SaleReturnDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.Date BETWEEN @MaxOpnDate AND @TDate
        GROUP BY H.Date, D.CodeID, D.BrandID

        UNION ALL

        SELECT
            [Date] = H.Date,
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            Price = MAX(dbo.GetMinPurPrice(D.CodeID, D.UnitID, ISNULL(D.Price, 0)))
                    + ISNULL(D.PurchasePrice, 0),
            Qty = SUM(dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty))
        FROM FinishGoodsHead H
        JOIN FinishGoodsDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.Date BETWEEN @MaxOpnDate AND @TDate
        GROUP BY H.Date, D.CodeID, D.BrandID, ISNULL(D.PurchasePrice, 0)

        UNION ALL

        SELECT
            [Date] = H.Date,
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            Price = MAX(dbo.GetMinPurPrice(D.CodeID, D.UnitID, ISNULL(D.Price, 0))),
            Qty = SUM(dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty))
        FROM AdjustmentHead H
        JOIN AdjustmentDetail D ON H.ID = D.RefID
        JOIN AdjustType AT ON D.AdjustTypeID = AT.ID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND AT.Type = N'+'
          AND H.Date BETWEEN @MaxOpnDate AND @TDate
        GROUP BY H.Date, D.BrandID, D.CodeID
    ) tmp
    WHERE ISNULL(Qty, 0) > 0
      AND ISNULL(Price, 0) > 0
    GROUP BY [Date], CodeID, BrandID, Price;

    CREATE CLUSTERED INDEX IX_Purchase_FIFO
        ON #_Purchase (Code, Brand, [Date], LotID);

    -------------------------------------------------------------------------
    -- Pre-period OUT (MaxOpnDate .. PreDate)  -- Ground aggregate, no GP record
    -------------------------------------------------------------------------
    CREATE TABLE #_PreSale
    (
        Code   INT   NOT NULL,
        Brand  INT   NOT NULL,
        SalQty FLOAT NOT NULL
    );

    INSERT INTO #_PreSale (Code, Brand, SalQty)
    SELECT CodeID, BrandID, ISNULL(SUM(Qty), 0)
    FROM
    (
        SELECT
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            Qty = ISNULL(SUM(ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0)), 0)
        FROM SaleHead H
        JOIN SaleDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND dbo.CastDate(H.Date) BETWEEN @MaxOpnDate AND @PreDate
        GROUP BY D.CodeID, D.BrandID

        UNION ALL

        SELECT
            D.CodeID,
            ISNULL(D.BrandID, -1),
            ISNULL(SUM(ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0)), 0)
        FROM RawIssueHead H
        JOIN RawIssueDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.Date BETWEEN @MaxOpnDate AND @PreDate
        GROUP BY D.CodeID, D.BrandID

        UNION ALL

        SELECT
            D.CodeID,
            ISNULL(D.BrandID, -1),
            ISNULL(SUM(ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0)), 0)
        FROM AdjustmentHead H
        JOIN AdjustmentDetail D ON H.ID = D.RefID
        JOIN AdjustType AT ON D.AdjustTypeID = AT.ID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND AT.Type = N'-'
          AND H.Date BETWEEN @MaxOpnDate AND @PreDate
        GROUP BY D.CodeID, D.BrandID
    ) x
    GROUP BY CodeID, BrandID
    HAVING ISNULL(SUM(Qty), 0) > 0;

    -------------------------------------------------------------------------
    -- Period OUT groups:
    --   SortKey 1 = RawIssue/Adjust- (consume only)
    --   SortKey 2 = Sale (record GP), aggregated by Date + min-unit SalePrice
    -------------------------------------------------------------------------
    CREATE TABLE #_PeriodOut
    (
        OutID      INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
        OutDate    DATETIME NOT NULL,
        SortKey    TINYINT  NOT NULL,  -- 1=other, 2=sale
        Code       INT      NOT NULL,
        Brand      INT      NOT NULL,
        SalQty     FLOAT    NOT NULL,
        SalePrice  MONEY    NULL,
        SaleAmount MONEY    NULL
    );

    INSERT INTO #_PeriodOut (OutDate, SortKey, Code, Brand, SalQty, SalePrice, SaleAmount)
    SELECT
        dbo.CastDate(H.Date),
        1,
        D.CodeID,
        ISNULL(D.BrandID, -1),
        ISNULL(SUM(ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0)), 0),
        NULL,
        NULL
    FROM RawIssueHead H
    JOIN RawIssueDetail D ON H.ID = D.RefID
    JOIN #Code C ON D.CodeID = C.c_id
    JOIN #Loc L ON H.LocationID = L.l_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate
    GROUP BY dbo.CastDate(H.Date), D.CodeID, D.BrandID
    HAVING ISNULL(SUM(ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0)), 0) > 0

    UNION ALL

    SELECT
        dbo.CastDate(H.Date),
        1,
        D.CodeID,
        ISNULL(D.BrandID, -1),
        ISNULL(SUM(ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0)), 0),
        NULL,
        NULL
    FROM AdjustmentHead H
    JOIN AdjustmentDetail D ON H.ID = D.RefID
    JOIN AdjustType AT ON D.AdjustTypeID = AT.ID
    JOIN #Code C ON D.CodeID = C.c_id
    JOIN #Loc L ON H.LocationID = L.l_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND AT.Type = N'-'
      AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate
    GROUP BY dbo.CastDate(H.Date), D.CodeID, D.BrandID
    HAVING ISNULL(SUM(ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0)), 0) > 0

    UNION ALL

    -- Sales out (Ground Qty = GetMinQty; SalePrice = Amount/MinQty min-unit)
    SELECT
        SaleDate,
        2,
        CodeID,
        BrandID,
        ISNULL(SUM(MinQty), 0),
        ROUND(SUM(Amount) / NULLIF(SUM(MinQty), 0), 4),
        ISNULL(SUM(Amount), 0)
    FROM
    (
        SELECT
            SaleDate = dbo.CastDate(H.Date),
            CodeID = D.CodeID,
            BrandID = ISNULL(D.BrandID, -1),
            MinQty = ISNULL(dbo.GetMinQty(D.CodeID, D.UnitID, ISNULL(D.Qty, 0)), 0),
            Amount = ISNULL(D.Amount, 0)
        FROM SaleHead H
        JOIN SaleDetail D ON H.ID = D.RefID
        JOIN #Code C ON D.CodeID = C.c_id
        JOIN #Loc L ON H.LocationID = L.l_id
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate
          AND ISNULL(D.Qty, 0) <> 0
    ) s
    WHERE MinQty > 0
    GROUP BY
        SaleDate,
        CodeID,
        BrandID,
        ROUND(Amount / NULLIF(MinQty, 0), 4)
    HAVING ISNULL(SUM(MinQty), 0) > 0;

    CREATE TABLE #_SaleCost
    (
        CodeID     INT   NOT NULL,
        SalePrice  MONEY NOT NULL,
        FIFOCost   MONEY NOT NULL,
        Qty        FLOAT NOT NULL,
        SaleAmount MONEY NOT NULL,
        CostAmount MONEY NOT NULL
    );

    -------------------------------------------------------------------------
    -- FIFO consume = Ground nested cursors (1 purchase walk per Code+Brand)
    -- Current lot kept in variables â†’ few UPDATEs (not every take)
    -------------------------------------------------------------------------
    DECLARE
        @SalCode INT,
        @SaleBrand INT,
        @SaleQty FLOAT,
        @tmpSaleQty FLOAT,
        @tmpDate DATETIME,
        @tmpPursQty FLOAT,
        @tmpPurchase_Price MONEY,
        @OutDate DATETIME,
        @SortKey TINYINT,
        @SalePrice MONEY,
        @SaleAmount MONEY,
        @TakeQty FLOAT,
        @NeedQty FLOAT,
        @Record BIT,
        @LotID INT,
        @HaveLot BIT,
        @FetchStat INT,
        @LastCost MONEY;

    -- 1) Pre-period OUT: one Purchas walk per Code+Brand (Ground)
    DECLARE PreCur CURSOR LOCAL FAST_FORWARD FOR
    SELECT Code, Brand, SalQty
    FROM #_PreSale
    WHERE SalQty > 0
    ORDER BY Code, Brand;

    OPEN PreCur;
    FETCH NEXT FROM PreCur INTO @SalCode, @SaleBrand, @SaleQty;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @tmpSaleQty = @SaleQty;
        SET @HaveLot = 0;

        DECLARE PrePurch CURSOR LOCAL FAST_FORWARD FOR
        SELECT LotID, [Date], PurQty, Price
        FROM #_Purchase
        WHERE Code = @SalCode
          AND Brand = @SaleBrand
          AND PurQty > 0
          AND [Date] <= @PreDate
        ORDER BY [Date], LotID;

        OPEN PrePurch;
        FETCH NEXT FROM PrePurch INTO @LotID, @tmpDate, @tmpPursQty, @tmpPurchase_Price;
        SET @FetchStat = @@FETCH_STATUS;
        IF @FetchStat = 0 SET @HaveLot = 1;

        WHILE @tmpSaleQty > 0 AND @HaveLot = 1
        BEGIN
            IF @tmpSaleQty >= @tmpPursQty
            BEGIN
                SET @tmpSaleQty = @tmpSaleQty - @tmpPursQty;
                UPDATE #_Purchase SET PurQty = 0 WHERE LotID = @LotID;
                FETCH NEXT FROM PrePurch INTO @LotID, @tmpDate, @tmpPursQty, @tmpPurchase_Price;
                SET @FetchStat = @@FETCH_STATUS;
                IF @FetchStat <> 0 SET @HaveLot = 0;
            END
            ELSE
            BEGIN
                UPDATE #_Purchase SET PurQty = @tmpPursQty - @tmpSaleQty WHERE LotID = @LotID;
                SET @tmpSaleQty = 0;
            END
        END

        CLOSE PrePurch;
        DEALLOCATE PrePurch;

        FETCH NEXT FROM PreCur INTO @SalCode, @SaleBrand, @SaleQty;
    END

    CLOSE PreCur;
    DEALLOCATE PreCur;

    -- Keep depleted lots (PurQty=0) as price history for shortage fallback.
    -- Cursors already filter PurQty > 0.

    -- 2) Period: outer = Code+Brand; purchase cursor once; outs walk in date order
    DECLARE CodeCur CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT Code, Brand
    FROM #_PeriodOut
    WHERE SalQty > 0
    ORDER BY Code, Brand;

    OPEN CodeCur;
    FETCH NEXT FROM CodeCur INTO @SalCode, @SaleBrand;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @HaveLot = 0;
        SET @tmpPurchase_Price = 0;
        -- Seed last known cost from any inbound layer (incl. already-depleted pre lots)
        SET @LastCost = 0;
        SELECT TOP 1 @LastCost = Price
        FROM #_Purchase
        WHERE Code = @SalCode
          AND Brand = @SaleBrand
          AND ISNULL(Price, 0) > 0
        ORDER BY [Date] DESC, LotID DESC;

        DECLARE PeriodPurch CURSOR LOCAL FAST_FORWARD FOR
        SELECT LotID, [Date], PurQty, Price
        FROM #_Purchase
        WHERE Code = @SalCode
          AND Brand = @SaleBrand
          AND PurQty > 0
        ORDER BY [Date], LotID;

        OPEN PeriodPurch;
        FETCH NEXT FROM PeriodPurch INTO @LotID, @tmpDate, @tmpPursQty, @tmpPurchase_Price;
        SET @FetchStat = @@FETCH_STATUS;
        IF @FetchStat = 0
        BEGIN
            SET @HaveLot = 1;
            IF ISNULL(@tmpPurchase_Price, 0) > 0
                SET @LastCost = @tmpPurchase_Price;
        END

        DECLARE OutCur CURSOR LOCAL FAST_FORWARD FOR
        SELECT OutDate, SortKey, SalQty, SalePrice, SaleAmount
        FROM #_PeriodOut
        WHERE Code = @SalCode
          AND Brand = @SaleBrand
          AND SalQty > 0
        ORDER BY OutDate, SortKey, OutID;

        OPEN OutCur;
        FETCH NEXT FROM OutCur INTO
            @OutDate, @SortKey, @SaleQty, @SalePrice, @SaleAmount;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @tmpSaleQty = @SaleQty;
            SET @NeedQty = @SaleQty;
            SET @Record = CASE WHEN @SortKey = 2 THEN 1 ELSE 0 END;
            -- Do NOT reset @LastCost  -- carry previous FIFO layer across outs / stock gaps

            WHILE @tmpSaleQty > 0
            BEGIN
                -- Later purchase cannot cover this OutDate (stock gap until that buy)
                IF @HaveLot = 0 OR @tmpDate > @OutDate
                    BREAK;

                IF @tmpSaleQty >= @tmpPursQty
                    SET @TakeQty = @tmpPursQty;
                ELSE
                    SET @TakeQty = @tmpSaleQty;

                IF ISNULL(@tmpPurchase_Price, 0) > 0
                    SET @LastCost = @tmpPurchase_Price;

                IF @Record = 1 AND @TakeQty > 0 AND @NeedQty > 0
                BEGIN
                    INSERT INTO #_SaleCost (CodeID, SalePrice, FIFOCost, Qty, SaleAmount, CostAmount)
                    VALUES
                    (
                        @SalCode,
                        ISNULL(@SalePrice, 0),
                        ROUND(@LastCost, 4),
                        @TakeQty,
                        ISNULL(@SaleAmount, 0) * @TakeQty / @NeedQty,
                        @TakeQty * @LastCost
                    );
                END

                SET @tmpSaleQty = @tmpSaleQty - @TakeQty;
                SET @tmpPursQty = @tmpPursQty - @TakeQty;

                IF @tmpPursQty <= 0
                BEGIN
                    UPDATE #_Purchase SET PurQty = 0 WHERE LotID = @LotID;
                    FETCH NEXT FROM PeriodPurch INTO
                        @LotID, @tmpDate, @tmpPursQty, @tmpPurchase_Price;
                    SET @FetchStat = @@FETCH_STATUS;
                    IF @FetchStat <> 0
                        SET @HaveLot = 0;
                END
            END

            -- Shortage / stock-gap: charge at last known FIFO price (never invent 0 when purchase existed)
            IF @Record = 1 AND @tmpSaleQty > 0 AND @NeedQty > 0
            BEGIN
                INSERT INTO #_SaleCost (CodeID, SalePrice, FIFOCost, Qty, SaleAmount, CostAmount)
                VALUES
                (
                    @SalCode,
                    ISNULL(@SalePrice, 0),
                    ROUND(ISNULL(@LastCost, 0), 4),
                    @tmpSaleQty,
                    ISNULL(@SaleAmount, 0) * @tmpSaleQty / @NeedQty,
                    @tmpSaleQty * ISNULL(@LastCost, 0)
                );
            END

            FETCH NEXT FROM OutCur INTO
                @OutDate, @SortKey, @SaleQty, @SalePrice, @SaleAmount;
        END

        CLOSE OutCur;
        DEALLOCATE OutCur;

        -- Persist leftover lot for this code (not fully consumed)
        IF @HaveLot = 1 AND @tmpPursQty > 0
            UPDATE #_Purchase SET PurQty = @tmpPursQty WHERE LotID = @LotID;

        CLOSE PeriodPurch;
        DEALLOCATE PeriodPurch;

        FETCH NEXT FROM CodeCur INTO @SalCode, @SaleBrand;
    END

    CLOSE CodeCur;
    DEALLOCATE CodeCur;

    DELETE FROM dbo.SaleProfitFIFO WHERE UserID = @UserID;

    INSERT INTO dbo.SaleProfitFIFO
    (
        UserID, SaleHeadID, SaleDetailID, Sr, [Date], AutoID, DocumentID,
        CustomerID, Customer, LocationID, Location, CodeID, BrandID,
        Qty, SalePrice, SaleAmount, FIFOCost, CostAmount, Profit
    )
    SELECT
        @UserID,
        0,
        0,
        NULL,
        @FDate,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        CodeID,
        -1,
        SUM(Qty),
        SalePrice,
        SUM(SaleAmount),
        FIFOCost,
        SUM(CostAmount),
        -- Markup % on cost: (SalePrice - FIFOCost) / FIFOCost * 100
        CASE
            WHEN ISNULL(FIFOCost, 0) = 0 THEN 0
            ELSE ROUND((SalePrice - FIFOCost) * 100.0 / FIFOCost, 2)
        END
    FROM #_SaleCost
    GROUP BY CodeID, SalePrice, FIFOCost;

    DROP TABLE #_SaleCost;
    DROP TABLE #_PeriodOut;
    DROP TABLE #_PreSale;
    DROP TABLE #_Purchase;
    DROP TABLE #Loc;
    DROP TABLE #Code;
END
GO

IF OBJECT_ID(N'dbo.SaleProfitFIFO', N'P') IS NOT NULL
    DROP PROC dbo.SaleProfitFIFO;
GO

PRINT '[OK] SaleProfitFIFO table + SaleProfitFIFO_SP CREATE OR ALTER';
GO

/*======================================================================
  4) GP_AVG  -- weighted average (client restore still uses AVG(Price))
     Current EXE Gross Profit (1145) calls SaleProfitFIFO_SP, not GP_AVG.
     This still updates GP_AVG so old EXE / SSMS callers are correct.
======================================================================*/
CREATE OR ALTER PROC [dbo].[GP_AVG]
(
    @UserID int = null,
    @FDate datetime = null,
    @TDate datetime = null,
    @Code nvarchar(1024) = null,
    @GroupID nvarchar(1024) = null,
    @TypeID nvarchar(1024) = null
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaxOpnDate Datetime,
            @PreDate Datetime;

    SET @PreDate = DATEADD(d, -1, @FDate);

    SELECT @MaxOpnDate = MAX(Date)
    FROM StockOpeningHead
    WHERE ISNULL(Deleted, 0) <> 1
      AND Date <= @FDate;

    IF @MaxOpnDate IS NULL
        SET @MaxOpnDate = '2025-01-28';

    DECLARE @SQL nvarchar(max);

    CREATE TABLE #Code (c_id int);

    IF LEN(@GroupID) > 0
    BEGIN
        SET @SQL = 'INSERT INTO #Code SELECT ID FROM Stock WHERE ISNULL(Deleted,0)<>1 AND GroupID IN (' + @GroupID + ')';
    END
    ELSE IF LEN(@TypeID) > 0
    BEGIN
        SET @SQL = 'INSERT INTO #Code SELECT ID FROM Stock WHERE ISNULL(Deleted,0)<>1 AND GroupID IN (SELECT ID FROM StockGroup WHERE TypeID IN (' + @TypeID + '))';
    END
    ELSE IF LEN(@Code) > 0
    BEGIN
        SET @SQL = 'INSERT INTO #Code SELECT ID FROM Stock WHERE ISNULL(Deleted,0)<>1 AND Short LIKE ''%' + @Code + '%''';
    END
    ELSE
    BEGIN
        SET @SQL = 'INSERT INTO #Code SELECT ID FROM Stock WHERE ISNULL(Deleted,0)<>1';
    END

    EXEC (@SQL);

    CREATE TABLE #TmpSale
    (
        CodeID int,
        Qty int,
        Amount money
    );

    INSERT INTO #TmpSale
    SELECT
        CodeID,
        Qty = SUM(dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty)),
        Amount = SUM(D.Amount)
    FROM SaleHead H
    JOIN SaleDetail D ON H.ID = D.RefID
    JOIN #Code ON D.CodeID = c_id
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate
    GROUP BY CodeID;

    DECLARE @CodeID int,
            @Qty int,
            @Amount money,
            @AvgPrice money,
            @BalQty int,
            @Short nvarchar(30);

    DELETE FROM GrossProfit
    WHERE UserID = @UserID;

    DECLARE Sales CURSOR FOR
    SELECT
        CodeID,
        Short,
        Qty,
        Amount
    FROM #TmpSale
    JOIN Stock ON CodeID = ID;

    OPEN Sales;
    FETCH NEXT FROM Sales INTO @CodeID, @Short, @Qty, @Amount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC StockValuationFIFO_Ground @UserID, @PreDate, @PreDate, @Short, NULL, NULL, NULL;

        SELECT @BalQty = SUM(Qty)
        FROM StockStatus
        WHERE UserID = @UserID;

        IF @BalQty >= @Qty
        BEGIN
            SELECT @AvgPrice = SUM(Qty * Price) / NULLIF(SUM(Qty), 0)
            FROM StockStatus
            WHERE UserID = @UserID;
        END
        ELSE
        BEGIN
            SELECT @AvgPrice = SUM(Qty * Price) / NULLIF(SUM(Qty), 0)
            FROM
            (
                SELECT Qty, Price
                FROM StockStatus
                WHERE UserID = @UserID

                UNION ALL

                SELECT
                    Qty = dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty),
                    Price = dbo.GetMinPurPrice(D.CodeID, D.UnitID, D.Price)
                FROM PurchaseHead H
                JOIN PurchaseDetail D ON H.ID = D.RefID
                WHERE ISNULL(H.Deleted, 0) <> 1
                  AND ISNULL(H.StockReceived, 0) = 1
                  AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate
                  AND D.CodeID = @CodeID

                UNION ALL

                SELECT
                    Qty = dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty),
                    Price = dbo.GetMinPurPrice(
                                D.CodeID,
                                D.UnitID,
                                ISNULL(D.Price, 0) + ISNULL(D.CostCon, 0) + ISNULL(D.CostTran, 0)
                            )
                FROM StockReceiveHead H
                JOIN StockReceiveDetail D ON H.ID = D.RefID
                WHERE ISNULL(H.Deleted, 0) <> 1
                  AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate
                  AND D.CodeID = @CodeID

                UNION ALL

                SELECT
                    Qty = dbo.GetMinQty(D.CodeID, D.UnitID, D.Qty),
                    Price = dbo.GetMinPurPrice(D.CodeID, D.UnitID, D.Price) + ISNULL(D.PurchasePrice, 0)
                FROM FinishGoodsHead H
                JOIN FinishGoodsDetail D ON H.ID = D.RefID
                WHERE ISNULL(H.Deleted, 0) <> 1
                  AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate
                  AND D.CodeID = @CodeID
            ) tmp;
        END

        INSERT INTO GrossProfit (UserID, CodeID, Qty, PurPrice, PurAmount, SaleAmount)
        SELECT
            @UserID,
            @CodeID,
            @Qty,
            ISNULL(@AvgPrice, 0),
            @Qty * ISNULL(@AvgPrice, 0),
            @Amount;

        FETCH NEXT FROM Sales INTO @CodeID, @Short, @Qty, @Amount;
    END

    CLOSE Sales;
    DEALLOCATE Sales;

    DROP TABLE #TmpSale;
    DROP TABLE #Code;
END
GO

PRINT '[OK] GP_AVG CREATE OR ALTER (weighted average)';
GO

/*======================================================================
  5) Report 1146 is not registered (Gross Profit 1145 only)
     Remove leftover menu/rights if a previous deploy inserted them.
======================================================================*/
DELETE FROM dbo.UserRights WHERE MenuSubID = 1146 AND MenuID = 3;
PRINT 'OK: Removed UserRights 1146 (rows=' + CAST(@@ROWCOUNT AS varchar(20)) + ')';

DELETE FROM dbo.ReportName WHERE ID = 1146;
PRINT 'OK: Removed ReportName 1146 (rows=' + CAST(@@ROWCOUNT AS varchar(20)) + ')';
GO

/*======================================================================
  6) Verification
======================================================================*/
PRINT '';
PRINT '===== VERIFICATION =====';

SELECT
    CheckName,
    Status
FROM
(
    SELECT 1 AS Ord, N'PurchaseReturnHead.StockChange' AS CheckName,
           CASE WHEN COL_LENGTH(N'dbo.PurchaseReturnHead', N'StockChange') IS NULL THEN N'MISSING' ELSE N'OK' END AS Status
    UNION ALL
    SELECT 2, N'ListviewItem PurReturn',
           CASE WHEN EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'PurReturn') THEN N'OK' ELSE N'MISSING' END
    UNION ALL
    SELECT 3, N'ListviewItem PurReturn.Payment',
           CASE WHEN EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'PurReturn' AND ColumnName = N'Payment') THEN N'OK' ELSE N'MISSING' END
    UNION ALL
    SELECT 4, N'SaleProfitFIFO table',
           CASE WHEN OBJECT_ID(N'dbo.SaleProfitFIFO', N'U') IS NULL THEN N'MISSING' ELSE N'OK' END
    UNION ALL
    SELECT 5, N'SaleProfitFIFO_SP',
           CASE WHEN OBJECT_ID(N'dbo.SaleProfitFIFO_SP', N'P') IS NULL THEN N'MISSING' ELSE N'OK' END
    UNION ALL
    SELECT 6, N'GP_AVG weighted',
           CASE
               WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.GP_AVG')) LIKE N'%SUM(Qty * Price)%' THEN N'OK'
               WHEN OBJECT_ID(N'dbo.GP_AVG') IS NULL THEN N'MISSING'
               ELSE N'STILL_OLD_AVG'
           END
    UNION ALL
    SELECT 7, N'ReportName 1146 absent',
           CASE WHEN EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1146) THEN N'STILL_PRESENT' ELSE N'OK' END
) v
ORDER BY Ord;

PRINT 'Finished: ' + CONVERT(varchar(19), GETDATE(), 120);
GO
