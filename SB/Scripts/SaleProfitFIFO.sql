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
    -- Pre-period OUT (MaxOpnDate .. PreDate) — Ground aggregate, no GP record
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
    -- Current lot kept in variables → few UPDATEs (not every take)
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
            -- Do NOT reset @LastCost — carry previous FIFO layer across outs / stock gaps

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
