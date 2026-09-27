/*
  LOCAL SB2 ONLY.

  After C2L IDENTITY_INSERT of an ID >= 2000000000, Local IDENT_CURRENT can sit
  in the cloud zone. The next Local insert then collides (duplicate 2000000000)
  or allocates another cloud-zone ID.

  Pull those identities back to MAX(ID) below 2000000000 (or 0 when every row
  is already in the cloud zone). Never RESEED Local up to the 2e9 floor.

  Do not run on db_abe8c0_sb2.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF DB_NAME() <> N'SB2'
   OR DB_NAME() IN (N'SB1', N'SB', N'db_abbe78_warehouse', N'db_abe8c0_erp', N'db_abe8c0_luckyone', N'db_abe8c0_sb2')
   OR DB_NAME() LIKE N'%warehouse%'
   OR DB_NAME() LIKE N'%luckyone%'
BEGIN
    RAISERROR(N'STOP: SB2_Reseed_LocalIdentity_BelowCloudFloor is Local SB2 only. Never reseed Local up to 2000000000, and do not run this on Cloud.', 16, 1);
    RETURN;
END

DECLARE @CloudFloor bigint = 2000000000;
DECLARE @tables TABLE (TableName sysname PRIMARY KEY);
INSERT @tables (TableName) VALUES
    (N'SaleHead'), (N'SaleDetail'),
    (N'PurchaseHead'), (N'PurchaseDetail'),
    (N'SaleOrderHead'), (N'SaleOrderDetail'),
    (N'SaleReturnHead'), (N'SaleReturnDetail'),
    (N'PurchaseOrderHead'), (N'PurchaseOrderDetail'),
    (N'PurchaseReturnHead'), (N'PurchaseReturnDetail'),
    (N'TransferHead'), (N'TransferDetail'),
    (N'AdjustmentHead'), (N'AdjustmentDetail'),
    (N'StockReceiveHead'), (N'StockReceiveDetail'),
    (N'IncomeExpenseHead'), (N'IncomeExpenseDetail'),
    (N'JournalHead'), (N'JournalDetail'),
    (N'ReturnReceiveHead'), (N'ReturnReceiveDetail'),
    (N'StockOpeningHead'), (N'StockOpeningDetail'),
    (N'RawIssueHead'), (N'RawIssueDetail'),
    (N'FinishGoodsHead'), (N'FinishGoodsDetail'),
    (N'ReturnStockHead'), (N'ReturnStockDetail'),
    (N'GetStockHead'), (N'GetStockDetail'),
    (N'AccountOpeningHead'), (N'AccountOpeningDetail'),
    (N'CustomerOpeningHead'), (N'CustomerOpeningDetail'),
    (N'SupplierOpeningHead'), (N'SupplierOpeningDetail'),
    (N'ManufacturerOpeningHead'), (N'ManufacturerOpeningDetail'),
    (N'CustSupTransfer');

PRINT N'=== Local identity pull-down below ' + CAST(@CloudFloor AS nvarchar(20)) + N' on ' + DB_NAME() + N' ===';

DECLARE @t sysname, @obj int, @idCol sysname, @sql nvarchar(max);
DECLARE @ident bigint, @localMax bigint, @newSeed bigint;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @tables ORDER BY TableName;
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

    SELECT @idCol = c.name FROM sys.identity_columns c WHERE c.object_id = @obj;
    IF @idCol IS NULL
    BEGIN
        PRINT N'SKIP (no identity): ' + @t;
        FETCH NEXT FROM cur INTO @t;
        CONTINUE;
    END

    SET @ident = IDENT_CURRENT(N'dbo.' + @t);
    IF @ident < @CloudFloor - 1
    BEGIN
        PRINT N'OK low: ' + @t + N' IDENT_CURRENT=' + CAST(@ident AS nvarchar(20));
        FETCH NEXT FROM cur INTO @t;
        CONTINUE;
    END

    SET @sql = N'SELECT @m = MAX(CAST(' + QUOTENAME(@idCol) + N' AS bigint)) FROM dbo.' + QUOTENAME(@t)
        + N' WHERE CAST(' + QUOTENAME(@idCol) + N' AS bigint) < @floor';
    SET @localMax = NULL;
    EXEC sp_executesql @sql, N'@m bigint OUTPUT, @floor bigint', @m = @localMax OUTPUT, @floor = @CloudFloor;
    SET @newSeed = ISNULL(@localMax, 0);
    IF @newSeed >= @CloudFloor
    BEGIN
        PRINT N'ERROR ' + @t + N': refused to reseed at or above the cloud floor.';
        FETCH NEXT FROM cur INTO @t;
        CONTINUE;
    END

    PRINT N'PULL DOWN ' + @t + N' IDENT_CURRENT=' + CAST(@ident AS nvarchar(20))
        + N' → RESEED ' + CAST(@newSeed AS nvarchar(20))
        + N' (next local insert ~' + CAST(@newSeed + 1 AS nvarchar(20)) + N')';

    SET @sql = N'DBCC CHECKIDENT (N''dbo.' + @t + N''', RESEED, ' + CAST(@newSeed AS nvarchar(20)) + N') WITH NO_INFOMSGS;';
    EXEC sp_executesql @sql;
    PRINT N'    now IDENT_CURRENT=' + CAST(IDENT_CURRENT(N'dbo.' + @t) AS nvarchar(20));

    FETCH NEXT FROM cur INTO @t;
END
CLOSE cur;
DEALLOCATE cur;

PRINT N'Local L2C inserts must omit the ID column. Do not IDENTITY_INSERT 2000000000 on Local.';
GO
