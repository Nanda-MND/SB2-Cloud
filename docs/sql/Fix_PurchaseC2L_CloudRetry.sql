/*
  CLOUD ONLY — retry Purchase C2L outbox after LocalWins unblock.

  Run AFTER: Fix_PurchaseC2L_LocalWinsUnblock.sql on LOCAL.

  Does:
    1) Ensure CaptureCloud=1 for PurchaseHead/Detail (+ triggers if helper exists)
    2) Reset Conflict / DeadLetter Purchase C2L → Pending
    3) Reset recent Synced cloud-zone Purchase C2L → Pending (re-pull missing rows)
    4) Touch active Cloud PurchaseHead so triggers re-queue if outbox empty
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== ' + DB_NAME() + N' — Purchase C2L Cloud retry ===';

IF DB_NAME() IN (N'SB1', N'SB') OR DB_NAME() NOT LIKE N'%abbe78%'
BEGIN
    -- Soft guard: Cloud hosted DB name usually contains abbe78/warehouse.
    PRINT N'WARN: Confirm this is CLOUD db_abbe78_warehouse before continuing.';
END
GO

PRINT N'=== 0) BEFORE — SyncConfig + recent outbox ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT TOP 30 OutboxID, Direction, TableName, Status, PrimaryKeyJson, AttemptCount,
       CreatedAt, SyncedAt, LEFT(ISNULL(LastError, N''), 100) AS Err
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Direction = N'C2L'
ORDER BY OutboxID DESC;

SELECT TOP 20 ID, Date, AutoID, ISNULL(Deleted,0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID DESC;
GO

PRINT N'=== 1) SyncConfig CaptureCloud=1 ===';
IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NOT NULL
BEGIN
    EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseHead';
    EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseDetail';
END
ELSE
    PRINT N'WARN: SyncInstall_CloudCapture missing — run DataSync_28 on Cloud if triggers absent.';

MERGE dbo.SyncConfig AS t
USING (VALUES
    (N'PurchaseHead',   1, 0, 1, N'ID',  50, 40, N'Purchase C2L retry'),
    (N'PurchaseDetail', 1, 0, 1, N'ID', 100, 45, N'Purchase C2L retry')
) AS s(TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
ON t.TableName = s.TableName
WHEN MATCHED THEN UPDATE SET
    IsEnabled = 1,
    CaptureLocal = 0,
    CaptureCloud = 1,
    Notes = LEFT(CONCAT(ISNULL(t.Notes, N''), N' | retry ',
                        CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHEN NOT MATCHED THEN INSERT
    (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
VALUES
    (s.TableName, s.IsEnabled, s.CaptureLocal, s.CaptureCloud,
     s.PrimaryKeyColumns, s.BatchSize, s.Priority, s.Notes);

SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT name AS TriggerName, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_PurchaseHead', N'tr_SyncOutbox_PurchaseDetail');
GO

PRINT N'=== 2) Reset Conflict / DeadLetter Purchase C2L → Pending ===';
UPDATE dbo.SyncOutbox
SET Status = N'Pending',
    AttemptCount = 0,
    LastError = NULL,
    SyncedAt = NULL
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status IN (N'Conflict', N'DeadLetter');

PRINT N'Conflict/DeadLetter reset: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== 3) Re-queue Synced cloud-zone Purchase C2L (last 30 days) ===';
UPDATE dbo.SyncOutbox
SET Status = N'Pending',
    AttemptCount = 0,
    LastError = NULL,
    SyncedAt = NULL
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status = N'Synced'
  AND CreatedAt >= DATEADD(day, -30, SYSUTCDATETIME())
  AND (
        PrimaryKeyJson LIKE N'%"ID":2%'
     OR PrimaryKeyJson LIKE N'%200000000%'
      );

PRINT N'Synced cloud-zone reset: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== 4) Touch active Cloud purchases so triggers emit fresh C2L if needed ===';
UPDATE dbo.PurchaseHead
SET Remark = ISNULL(Remark, N'')
WHERE ID >= 2000000000
  AND ISNULL(Deleted, 0) = 0;

PRINT N'PurchaseHead touched: ' + CAST(@@ROWCOUNT AS nvarchar(20));

UPDATE dbo.PurchaseDetail
SET Qty = Qty
WHERE RefID >= 2000000000
  AND ISNULL(IsDeleted, 0) = 0;  -- Detail has IsDeleted, not Deleted

PRINT N'PurchaseDetail touched: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== AFTER — Pending C2L must appear ===';
SELECT TOP 40 OutboxID, TableName, Status, PrimaryKeyJson, AttemptCount, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status IN (N'Pending', N'Syncing', N'Conflict')
ORDER BY OutboxID DESC;

PRINT N'';
PRINT N'If NEW Cloud IDs (2000000002+) still have no Pending above, run:';
PRINT N'  docs/sql/Fix_PurchaseC2L_CloudForceEnqueue.sql';
PRINT N'(That script inserts C2L outbox directly — needed when C2L trigger never fired.)';
PRINT N'';
PRINT N'Keep SyncAgent running. On LOCAL after pull:';
PRINT N'  SELECT ID, Deleted, SyncOrigin, SyncModifiedAt FROM PurchaseHead WHERE ID >= 2000000000;';
PRINT N'  SELECT ID, RefID, CodeID, Qty FROM PurchaseDetail WHERE RefID >= 2000000000;';
GO
