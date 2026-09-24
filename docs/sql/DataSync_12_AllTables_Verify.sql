/*
  Verify all-table sync readiness.
  Run after Deploy-AllTablesSync.cmd
*/

SET NOCOUNT ON;
GO

PRINT '=== SyncConfig (enabled tables) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, Priority
FROM dbo.SyncConfig
WHERE IsEnabled = 1
ORDER BY Priority, TableName;
GO

PRINT '=== Trigger counts ===';
SELECT
    SUM(CASE WHEN name LIKE 'tr_SyncOutbox_%' THEN 1 ELSE 0 END) AS OutboxTriggers,
    SUM(CASE WHEN name LIKE 'tr_%_SyncMetadata' THEN 1 ELSE 0 END) AS MetadataTriggers,
    SUM(CASE WHEN name LIKE 'tr_SyncBlockDelete_%' THEN 1 ELSE 0 END) AS BlockDeleteTriggers
FROM sys.triggers
WHERE parent_class = 1;
GO

PRINT '=== Tables missing sync columns ===';
SELECT t.name AS TableName
FROM sys.tables t
INNER JOIN dbo.SyncConfig c ON c.TableName = t.name AND c.IsEnabled = 1
WHERE COL_LENGTH(t.name, 'SyncModifiedAt') IS NULL
   OR COL_LENGTH(t.name, 'SyncOrigin') IS NULL;
GO

PRINT '=== SyncApply_Generic exists ===';
SELECT name, create_date, modify_date
FROM sys.procedures
WHERE name = 'SyncApply_Generic';
GO

PRINT '=== Pending outbox (sample) ===';
SELECT TOP 20 OutboxID, TableName, Operation, Status, CreatedAt
FROM dbo.SyncOutbox
WHERE Status = 'Pending'
ORDER BY CreatedAt;
GO
