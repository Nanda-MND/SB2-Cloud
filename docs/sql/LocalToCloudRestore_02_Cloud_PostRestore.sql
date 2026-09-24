/*
  Post-restore cleanup — run on CLOUD after restoring Local .bak

  sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P xxx -C -I -i LocalToCloudRestore_02_Cloud_PostRestore.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Cloud post-restore: ' + DB_NAME() + ' ===';

-- 1) Drop LOCAL capture triggers (must not run on cloud)
DECLARE @sql nvarchar(max) = N'';
SELECT @sql += N'DROP TRIGGER ' + QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) + N';' + CHAR(13)
FROM sys.triggers t
WHERE t.name LIKE N'tr_SyncOutbox_%'
   OR t.name LIKE N'tr_SyncBlockDelete_%';
IF LEN(@sql) > 0 EXEC sp_executesql @sql;
PRINT 'Capture/block-delete triggers dropped.';

-- 2) SyncConfig — inbound only
UPDATE dbo.SyncConfig SET CaptureLocal = 0, IsEnabled = 1;
PRINT 'SyncConfig: CaptureLocal=0, IsEnabled=1';

-- 3) Clear queues copied from local
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL DELETE FROM dbo.SyncOutbox;
IF OBJECT_ID(N'dbo.SyncDeadLetter', N'U') IS NOT NULL DELETE FROM dbo.SyncDeadLetter;
IF OBJECT_ID(N'dbo.SyncConflictLog', N'U') IS NOT NULL DELETE FROM dbo.SyncConflictLog;
PRINT 'SyncOutbox / DeadLetter / ConflictLog cleared.';

-- 4) Verify apply proc
IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
    PRINT 'WARNING: Run DataSync_10_SyncApply_Generic.sql then DataSync_21_EnableAllCloudInbound.sql';

SELECT COUNT(*) AS EnabledTables FROM dbo.SyncConfig WHERE IsEnabled = 1;
SELECT COUNT(*) AS BadCaptureTriggers FROM sys.triggers WHERE name LIKE N'tr_SyncOutbox_%';
GO
