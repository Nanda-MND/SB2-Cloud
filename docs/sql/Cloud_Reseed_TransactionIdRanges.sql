/*
  CLOUD ONLY — Transaction identity RESEED for C2L ID ranges.

  DO NOT run on Local / live client DB.
  Local ERP keeps normal identity (low IDs). Clients unchanged.

  Default Cloud floor = 2,000,000,000
  Local expected zone = 1 .. (floor - 1)
  int max            = 2,147,483,647
  Cloud spare IDs    ≈ 147 million (at default floor)

  100:1 traffic (Local:Cloud): Local burns IDs much faster.
  Watch Local MAX(ID) approaching @CloudFloor — raise floor only on CLOUD
  (until int ceiling). Never RESEED Local for this plan.

  Before enable txn C2L capture, run this on Cloud once (or after verify).

  Table list matches Fix_AllTxn_Cloud_C2L_Capture.sql (Sale/Purchase/Transfer
  plus ReturnReceive, StockOpening, RawIssue, FinishGoods, ReturnStock, GetStock,
  openings, CustSupTransfer). Missing tables SKIP. Never run on Local SB2.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ========== CONFIG ==========
DECLARE @CloudFloor bigint = 2000000000;   -- change only if Local MAX already near this
DECLARE @IntMax     bigint = 2147483647;
DECLARE @DryRun     bit    = 0;            -- 1 = report only, no RESEED

IF @CloudFloor >= @IntMax
BEGIN
    RAISERROR(N'@CloudFloor must be < int max (2147483647).', 16, 1);
    RETURN;
END

PRINT '=== CLOUD identity RESEED ===';
PRINT 'Database: ' + DB_NAME();
PRINT 'CloudFloor: ' + CAST(@CloudFloor AS nvarchar(20));
PRINT 'DryRun: ' + CAST(@DryRun AS nvarchar(5));
PRINT 'WARNING: Run on CLOUD only (db_abe8c0_sb2). Do not run on Local SB2.';
PRINT '';

IF DB_NAME() IN (N'SB2', N'SB1', N'SB', N'db_abbe78_warehouse', N'db_abe8c0_erp', N'db_abe8c0_luckyone')
   OR DB_NAME() LIKE N'%warehouse%'
   OR DB_NAME() LIKE N'%luckyone%'
   OR DB_NAME() LIKE N'%SB1%'
BEGIN
    RAISERROR(N'STOP: Cloud_Reseed_TransactionIdRanges is CLOUD ONLY. Refusing Local SB2 / SB1 / production. Never RESEED Local up to the 2e9 floor.', 16, 1);
    RETURN;
END

DECLARE @tables TABLE (TableName sysname PRIMARY KEY, Sort int);
INSERT @tables (TableName, Sort) VALUES
    (N'SaleHead', 10), (N'SaleDetail', 11),
    (N'PurchaseHead', 20), (N'PurchaseDetail', 21),
    (N'SaleOrderHead', 30), (N'SaleOrderDetail', 31),
    (N'SaleReturnHead', 40), (N'SaleReturnDetail', 41),
    (N'PurchaseOrderHead', 50), (N'PurchaseOrderDetail', 51),
    (N'PurchaseReturnHead', 60), (N'PurchaseReturnDetail', 61),
    (N'TransferHead', 70), (N'TransferDetail', 71),
    (N'AdjustmentHead', 80), (N'AdjustmentDetail', 81),
    (N'StockReceiveHead', 90), (N'StockReceiveDetail', 91),
    (N'IncomeExpenseHead', 100), (N'IncomeExpenseDetail', 101),
    (N'JournalHead', 110), (N'JournalDetail', 111),
    (N'ReturnReceiveHead', 120), (N'ReturnReceiveDetail', 121),
    (N'StockOpeningHead', 130), (N'StockOpeningDetail', 131),
    (N'RawIssueHead', 140), (N'RawIssueDetail', 141),
    (N'FinishGoodsHead', 150), (N'FinishGoodsDetail', 151),
    (N'ReturnStockHead', 160), (N'ReturnStockDetail', 161),
    (N'GetStockHead', 170), (N'GetStockDetail', 171),
    (N'AccountOpeningHead', 180), (N'AccountOpeningDetail', 181),
    (N'CustomerOpeningHead', 190), (N'CustomerOpeningDetail', 191),
    (N'SupplierOpeningHead', 200), (N'SupplierOpeningDetail', 201),
    (N'ManufacturerOpeningHead', 210), (N'ManufacturerOpeningDetail', 211),
    (N'CustSupTransfer', 220);

DECLARE @t sysname, @obj int, @idCol sysname, @sql nvarchar(max);
DECLARE @maxId bigint, @ident bigint, @newSeed bigint;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName FROM @tables ORDER BY Sort;
OPEN cur;
FETCH NEXT FROM cur INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = OBJECT_ID(N'dbo.' + @t);
    IF @obj IS NULL
    BEGIN
        PRINT N'SKIP (missing): ' + @t;
        FETCH NEXT FROM cur INTO @t;
        CONTINUE;
    END

    SELECT @idCol = c.name
    FROM sys.identity_columns c
    WHERE c.object_id = @obj;

    IF @idCol IS NULL
    BEGIN
        PRINT N'SKIP (no identity): ' + @t;
        FETCH NEXT FROM cur INTO @t;
        CONTINUE;
    END

    SET @sql = N'SELECT @m = ISNULL(MAX(CAST(' + QUOTENAME(@idCol) + N' AS bigint)), 0) FROM dbo.' + QUOTENAME(@t);
    EXEC sp_executesql @sql, N'@m bigint OUTPUT', @m = @maxId OUTPUT;

    SET @ident = IDENT_CURRENT(N'dbo.' + @t);

    IF @maxId >= @CloudFloor
    BEGIN
        PRINT N'WARN ' + @t + N': MAX(ID)=' + CAST(@maxId AS nvarchar(20))
            + N' already >= CloudFloor. Raising seed above MAX.';
        SET @newSeed = @maxId;  -- CHECKIDENT RESEED sets next = value+1 on next insert behavior varies; use max
    END
    ELSE
        SET @newSeed = @CloudFloor - 1; -- next insert typically CloudFloor when reseed to floor-1... 
    -- SQL Server: DBCC CHECKIDENT (table, RESEED, new_reseed_value)
    -- Next identity = new_reseed_value + 1 when rows exist; if reseed to N, next is N+1.
    -- We want next ID >= @CloudFloor → RESEED (@CloudFloor - 1) when empty/low, or RESEED(@maxId) if max higher.

    IF @maxId >= @CloudFloor
        SET @newSeed = @maxId;          -- next ≈ max+1
    ELSE
        SET @newSeed = @CloudFloor - 1; -- next ≈ CloudFloor

    IF @newSeed + 1 > @IntMax
    BEGIN
        PRINT N'ERROR ' + @t + N': next ID would exceed int max. Abort this table.';
        FETCH NEXT FROM cur INTO @t;
        CONTINUE;
    END

    PRINT N'--- ' + @t + N'.' + @idCol
        + N' MAX=' + CAST(@maxId AS nvarchar(20))
        + N' IDENT_CURRENT=' + CAST(@ident AS nvarchar(20))
        + N' → RESEED ' + CAST(@newSeed AS nvarchar(20))
        + N' (next ~' + CAST(@newSeed + 1 AS nvarchar(20)) + N')';

    IF @DryRun = 0
    BEGIN
        SET @sql = N'DBCC CHECKIDENT (N''dbo.' + @t + N''', RESEED, ' + CAST(@newSeed AS nvarchar(20)) + N') WITH NO_INFOMSGS;';
        EXEC sp_executesql @sql;
        PRINT N'    RESEED done. New IDENT_CURRENT=' + CAST(IDENT_CURRENT(N'dbo.' + @t) AS nvarchar(20));
    END
    ELSE
        PRINT N'    DryRun — not applied.';

    FETCH NEXT FROM cur INTO @t;
END
CLOSE cur;
DEALLOCATE cur;

PRINT '';
PRINT '=== Verify (Cloud) ===';
SELECT
    t.TableName,
    IDENT_CURRENT(N'dbo.' + t.TableName) AS IdentCurrent,
    CASE
        WHEN OBJECT_ID(N'dbo.' + t.TableName) IS NULL THEN N'MISSING'
        WHEN IDENT_CURRENT(N'dbo.' + t.TableName) IS NULL THEN N'NO_IDENTITY'
        WHEN IDENT_CURRENT(N'dbo.' + t.TableName) >= @CloudFloor - 1 THEN N'OK_CLOUD_ZONE'
        ELSE N'BELOW_FLOOR'
    END AS Status
FROM @tables t
ORDER BY t.Sort;

PRINT '';
PRINT 'Next: enable C2L capture for chosen txn tables (Sale first).';
PRINT 'Local: do NOT run this script. Clients: no change.';
GO
