/*
  Cloud database - check sync structure is ready to RECEIVE data from Local.
  Run on Cloud: db_abbe78_warehouse (site4now.net)
  No ERP code changes needed - only run missing SQL scripts on Cloud.
*/

SET NOCOUNT ON;
GO

PRINT '=== 1. Sync infrastructure tables ===';
SELECT name AS MissingObject
FROM (VALUES
    ('SyncConfig'), ('SyncOutbox'), ('SyncState'), ('SyncConflictLog'), ('SyncDeadLetter')
) v(name)
WHERE OBJECT_ID('dbo.' + v.name, 'U') IS NULL;
GO

PRINT '=== 2. Apply stored procedures (required on Cloud) ===';
SELECT name AS MissingProcedure
FROM (VALUES
    ('SyncApply_Customer'), ('SyncApply_SaleHead'), ('SyncApply_SaleDetail'),
    ('SyncClaimOutboxBatch'), ('SyncCompleteOutbox')
) v(name)
WHERE OBJECT_ID('dbo.' + v.name, 'P') IS NULL;
GO

PRINT '=== 3. Customer sync columns ===';
SELECT col = c.name
FROM (VALUES
    ('IsDeleted'), ('DeletedAt'), ('SyncModifiedAt'), ('SyncModifiedBy'), ('SyncOrigin'), ('SyncRowVersion')
) c(name)
WHERE COL_LENGTH('dbo.Customer', c.name) IS NULL;
GO

PRINT '=== 4. SaleHead sync columns (if using Sales sync) ===';
SELECT col = c.name
FROM (VALUES
    ('IsDeleted'), ('SyncModifiedAt'), ('SyncOrigin')
) c(name)
WHERE OBJECT_ID('dbo.SaleHead', 'U') IS NOT NULL
  AND COL_LENGTH('dbo.SaleHead', c.name) IS NULL;
GO

PRINT '=== 5. SyncConfig enabled tables ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE IsEnabled = 1
ORDER BY Priority;
GO

PRINT '=== 6. Cloud Customer row count + latest sync time ===';
IF OBJECT_ID('dbo.Customer', 'U') IS NOT NULL
    SELECT COUNT(*) AS CustomerRows, MAX(SyncModifiedAt) AS LatestSyncModifiedAt
    FROM dbo.Customer;
GO

PRINT '';
PRINT 'If anything is MISSING above, run on Cloud in this order:';
PRINT '  1. DataSync_01_Schema.sql';
PRINT '  2. DataSync_04_SoftDelete_Migration.sql';
PRINT '  3. DataSync_03_ApplyInbound.sql';
PRINT '  4. DataSync_05_Sales.sql  (only if enabling Sales)';
PRINT '';
PRINT 'Cloud does NOT need DataSync_02 triggers (capture runs on Local only).';
GO
