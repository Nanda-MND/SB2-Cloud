/*
  SyncOutbox maintenance — reclaim space AFTER full sync (Pending=0 recommended).

  WARNING:
  - Stop agent OR run when Pending=0 only
  - Deletes Synced history from SyncOutbox (safe for sync; Cloud already has data)
  - Optional SHRINK — use only after large DELETE

  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -i DataSync_25_OutboxMaintenance.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @Pending int = (
    SELECT COUNT(*) FROM dbo.SyncOutbox
    WHERE Direction = N'L2C' AND Status IN (N'Pending', N'Syncing')
);

IF @Pending > 0
BEGIN
    PRINT 'WARNING: ' + CAST(@Pending AS nvarchar(20)) + ' rows still Pending/Syncing.';
    PRINT 'Prefer running after full sync. Continue only if intentional.';
END

PRINT '=== Before ===';
SELECT Status, COUNT(*) AS Cnt FROM dbo.SyncOutbox WHERE Direction = N'L2C' GROUP BY Status;

DECLARE @del bigint;
DELETE FROM dbo.SyncOutbox
WHERE Direction = N'L2C' AND Status = N'Synced';
SET @del = @@ROWCOUNT;
PRINT 'Deleted Synced rows: ' + CAST(@del AS nvarchar(20));

-- Old DeadLetter with no retry value (optional — uncomment if desired)
-- DELETE FROM dbo.SyncOutbox WHERE Direction = N'L2C' AND Status = N'DeadLetter';

DELETE FROM dbo.SyncDeadLetter
WHERE FailedAt < DATEADD(day, -30, sysutcdatetime());
PRINT 'SyncDeadLetter cleaned (30d+): ' + CAST(@@ROWCOUNT AS nvarchar(20));

PRINT '=== Rebuild SyncOutbox indexes ===';
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.SyncOutbox') AND name = N'IX_SyncOutbox_Pending')
    ALTER INDEX IX_SyncOutbox_Pending ON dbo.SyncOutbox REBUILD;

PRINT '=== After ===';
SELECT Status, COUNT(*) AS Cnt FROM dbo.SyncOutbox WHERE Direction = N'L2C' GROUP BY Status;

PRINT '=== DB size (run SHRINK manually if needed) ===';
SELECT
    name,
    CAST(size * 8.0 / 1024 AS decimal(10, 2)) AS SizeMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS decimal(10, 2)) AS UsedMB
FROM sys.database_files;

/*
  Optional — only after large DELETE and ONLY on data file, not log without backup policy review:

  DBCC SHRINKFILE (N'SB1', 500);  -- target MB — adjust to your baseline

  Or:
  ALTER DATABASE SB1 SET RECOVERY SIMPLE;
  CHECKPOINT;
  DBCC SHRINKFILE (2, TRUNCATEONLY); -- log file id may differ
*/
GO
