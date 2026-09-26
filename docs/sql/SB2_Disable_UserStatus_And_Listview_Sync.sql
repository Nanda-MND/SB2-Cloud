/*
  Dev Local (SB2) AND Test Cloud (db_abe8c0_sb2).

  UserStatus is not synced. UserRights stays L2C-only (this script does not touch it).
  ListviewItem / ListViewItem is UI column config, not a sync table — stop capture.
  Users stays enabled (master in DataSync_15_ERPTransactionTables.sql).

  Sets IsEnabled=0, CaptureLocal=0, CaptureCloud=0.
  Drops Sync* triggers on those tables.
  Removes Pending/Syncing/DeadLetter outbox rows so a disabled table cannot sit in L2C forever
  (SyncApply_Generic raises if IsEnabled <> 1).

  Does NOT drop dbo.UserStatus_CleanupGhosts (Cloud_UserStatus_GhostCleanup.sql).
  Does NOT make UserStatus bidirectional.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF DB_NAME() IN (N'SB1', N'SB', N'db_abbe78_warehouse', N'db_abe8c0_erp', N'db_abe8c0_luckyone')
   OR DB_NAME() LIKE N'%warehouse%'
   OR DB_NAME() LIKE N'%luckyone%'
   OR DB_NAME() LIKE N'%SB1%'
BEGIN
    RAISERROR(N'STOP: refusing SB1 / production catalog.', 16, 1);
    RETURN;
END

PRINT N'=== Disable UserStatus + ListviewItem sync on ' + DB_NAME() + N' ===';

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
BEGIN
    RAISERROR(N'dbo.SyncConfig missing.', 16, 1);
    RETURN;
END

UPDATE c
SET IsEnabled = 0,
    CaptureLocal = 0,
    CaptureCloud = 0,
    Notes = LEFT(CONCAT(N'Not synced ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126), N' | ', ISNULL(c.Notes, N'')), 500)
FROM dbo.SyncConfig c
WHERE c.TableName IN (N'UserStatus', N'ListviewItem', N'ListViewItem');
PRINT N'SyncConfig rows set not-synced: ' + CAST(@@ROWCOUNT AS nvarchar(20));

DECLARE @tr sysname, @sql nvarchar(max);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT tr.name
    FROM sys.triggers tr
    INNER JOIN sys.tables t ON t.object_id = tr.parent_id
    INNER JOIN sys.schemas sch ON sch.schema_id = t.schema_id AND sch.name = N'dbo'
    WHERE t.name IN (N'UserStatus', N'ListviewItem', N'ListViewItem')
      AND tr.name LIKE N'%Sync%';

OPEN cur;
FETCH NEXT FROM cur INTO @tr;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'DROP TRIGGER dbo.' + QUOTENAME(@tr);
    EXEC sp_executesql @sql;
    PRINT N'Dropped trigger ' + @tr;
    FETCH NEXT FROM cur INTO @tr;
END
CLOSE cur;
DEALLOCATE cur;

IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
BEGIN
    DELETE o
    FROM dbo.SyncOutbox o
    WHERE o.TableName IN (N'UserStatus', N'ListviewItem', N'ListViewItem')
      AND o.Status IN (N'Pending', N'Syncing', N'DeadLetter');
    PRINT N'Outbox Pending/Syncing/DeadLetter removed: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END

IF OBJECT_ID(N'dbo.SyncDeadLetter', N'U') IS NOT NULL
BEGIN
    DELETE d
    FROM dbo.SyncDeadLetter d
    WHERE d.TableName IN (N'UserStatus', N'ListviewItem', N'ListViewItem');
    PRINT N'SyncDeadLetter removed: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END

PRINT N'Users sync is unchanged (master in DataSync_15).';
PRINT N'UserStatus_CleanupGhosts object_id='
    + ISNULL(CAST(OBJECT_ID(N'dbo.UserStatus_CleanupGhosts', N'P') AS nvarchar(20)), N'(absent on Local is OK)');

SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'UserStatus', N'ListviewItem', N'ListViewItem', N'UserRights', N'Users')
ORDER BY TableName;

PRINT N'Expect UserStatus IsEnabled=0 CaptureLocal=0 CaptureCloud=0.';
PRINT N'Expect UserRights unchanged (Local 1/1/0, Cloud 1/0/0).';
GO
