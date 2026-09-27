-- GP_AVG: weighted average cost fix (replaces AVG(Price) with SUM(Qty*Price)/SUM(Qty)).
-- Also fixes TypeID filter dynamic SQL parenthesis and removes debug select @SQL.
-- Report: frm_Preview case 1145 -> GrossProfit.rpt
-- Run once on the ERP database.

ALTER PROC [dbo].[GP_AVG]
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
