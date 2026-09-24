/*
  CLOUD — after DataSync_35_EnableC2L_Transfer.sql
  Diagnose + queue existing TransferHead 2000000000 for C2L.
*/

SET NOCOUNT ON;

PRINT '=== Transfer C2L config ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig
WHERE TableName IN (N'TransferHead', N'TransferDetail');

PRINT '=== Triggers ===';
SELECT name, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name LIKE N'tr_SyncOutbox_Transfer%';

PRINT '=== Cloud-zone TransferHead (top 10) ===';
SELECT TOP 10 ID, Date, AutoID, UserID, FromLocID, ToLocID, Remark, SyncOrigin, SyncModifiedAt
FROM dbo.TransferHead
WHERE ID >= 2000000000
ORDER BY ID DESC;

PRINT '=== Recent C2L Transfer outbox ===';
SELECT TOP 20 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt,
       LEFT(ISNULL(LastError, N''), 100) AS LastError
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'TransferHead', N'TransferDetail')
ORDER BY OutboxID DESC;
GO

-- Touch known Cloud transfer so trigger writes outbox (uncomment to run)
/*
UPDATE dbo.TransferHead
SET Remark = ISNULL(Remark, N'') + N' [C2L-queue]'
WHERE ID = 2000000000;

UPDATE dbo.TransferDetail
SET Qty = Qty
WHERE RefID = 2000000000;

SELECT TOP 10 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName LIKE N'Transfer%'
ORDER BY OutboxID DESC;
*/
GO
