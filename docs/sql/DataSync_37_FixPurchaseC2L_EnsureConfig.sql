/*
  CLOUD — Fix Purchase C2L (also works for Transfer if you change table names).

  Root cause: SyncInstall_CloudCapture only UPDATEs SyncConfig.
  If PurchaseHead/Detail rows are missing, CaptureCloud never sticks → no C2L outbox.

  Run entire script on CLOUD. Then check Local after Agent pull.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT '=== 0. Diagnose BEFORE ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT name, OBJECT_NAME(parent_id) ParentTable, is_disabled
FROM sys.triggers
WHERE name LIKE N'tr_SyncOutbox_Purchase%';

SELECT TOP 10 OutboxID, Direction, TableName, Status, PrimaryKeyJson, CreatedAt,
       LEFT(ISNULL(LastError,N''), 100) Err
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY OutboxID DESC;
GO

PRINT '=== 1. Ensure SyncConfig rows exist ===';
MERGE dbo.SyncConfig AS t
USING (VALUES
    (N'PurchaseHead',   1, 0, 1, N'ID',  50, 22, N'Purchase C2L'),
    (N'PurchaseDetail', 1, 0, 1, N'ID', 100, 23, N'Purchase C2L')
) AS s(TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
ON t.TableName = s.TableName
WHEN MATCHED THEN UPDATE SET
    IsEnabled = 1,
    CaptureLocal = 0,
    CaptureCloud = 1,
    Notes = LEFT(CONCAT(ISNULL(t.Notes, N''), N' | C2L ensure ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHEN NOT MATCHED THEN INSERT
    (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
VALUES
    (s.TableName, s.IsEnabled, s.CaptureLocal, s.CaptureCloud, s.PrimaryKeyColumns, s.BatchSize, s.Priority, s.Notes);

PRINT 'SyncConfig MERGE rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));
GO

PRINT '=== 2. Install C2L triggers ===';
IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
BEGIN
    RAISERROR(N'Missing SyncInstall_CloudCapture — run DataSync_28 on Cloud first.', 16, 1);
    RETURN;
END

EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseHead';
EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseDetail';

UPDATE dbo.SyncConfig
SET IsEnabled = 1, CaptureCloud = 1, CaptureLocal = 0
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');
GO

PRINT '=== 3. Queue existing Cloud purchase 2000000000 ===';
UPDATE dbo.PurchaseHead
SET Remark = ISNULL(Remark, N'') + N' [C2L-fix]'
WHERE ID = 2000000000;

UPDATE dbo.PurchaseDetail
SET Qty = Qty
WHERE RefID = 2000000000;

PRINT 'Head updated: check @@ROWCOUNT in messages; Detail touch done.';
GO

PRINT '=== 4. Diagnose AFTER (must show C2L Pending) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT name, OBJECT_NAME(parent_id) ParentTable, is_disabled
FROM sys.triggers
WHERE name LIKE N'tr_SyncOutbox_Purchase%';

SELECT TOP 20 OutboxID, Direction, TableName, Status, PrimaryKeyJson, CreatedAt,
       LEFT(ISNULL(LastError,N''), 120) Err
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY OutboxID DESC;
GO

PRINT 'LOCAL once:';
PRINT '  UPDATE dbo.SyncConfig SET IsEnabled=1, CaptureCloud=0 WHERE TableName IN (N''PurchaseHead'',N''PurchaseDetail'');';
PRINT 'Then wait for Agent pull; Local: SELECT * FROM PurchaseDetail WHERE RefID=2000000000;';
GO
