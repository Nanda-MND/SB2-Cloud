/*
  Re-queue Setting L2C after Local trigger fix.

  Run on LOCAL after DataSync_30_RestoreLocalL2C_AfterC2LMistake.sql

  1) Removes wrong C2L outbox rows for Setting on Local
  2) Re-captures current Setting row into L2C Pending
*/

SET NOCOUNT ON;

DELETE FROM dbo.SyncOutbox
WHERE TableName = N'Setting' AND Direction = N'C2L';
PRINT 'Deleted Local C2L Setting rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

IF OBJECT_ID(N'dbo.tr_SyncOutbox_Setting', N'TR') IS NULL
BEGIN
    RAISERROR(N'Missing tr_SyncOutbox_Setting. Run DataSync_30 first.', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'Setting' AND CaptureLocal = 1)
BEGIN
    RAISERROR(N'Setting CaptureLocal=0. Run DataSync_30 or SyncInstall_Table for Setting.', 16, 1);
    RETURN;
END

-- Touch row to fire L2C capture (metadata only bump)
UPDATE dbo.Setting
SET SyncModifiedAt = sysutcdatetime()
WHERE ID = 1;

SELECT TOP 5 OutboxID, Direction, Status, CreatedAt, LEFT(PayloadJson, 150) AS PayloadPreview
FROM dbo.SyncOutbox WHERE TableName = N'Setting' ORDER BY OutboxID DESC;
GO
