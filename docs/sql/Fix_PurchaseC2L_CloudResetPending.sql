/*
  CLOUD — reset Purchase C2L Conflict/Syncing/Synced → Pending so Agent retries.

  Run AFTER LocalWinsUnblock on LOCAL.
  If AttemptCount stays 0 → SyncAgent is not pulling (restart Agent).
*/

SET NOCOUNT ON;

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'CLOUD only.', 16, 1);
    RETURN;
END

-- Unstick Syncing
UPDATE dbo.SyncOutbox
SET Status = N'Pending', AttemptCount = 0, LastError = NULL, SyncedAt = NULL
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status = N'Syncing';

PRINT N'Syncing→Pending: ' + CAST(@@ROWCOUNT AS nvarchar(20));

UPDATE dbo.SyncOutbox
SET Status = N'Pending', AttemptCount = 0, LastError = NULL, SyncedAt = NULL
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status IN (N'Conflict', N'DeadLetter', N'Synced')
  AND CreatedAt >= DATEADD(day, -60, SYSUTCDATETIME())
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');

PRINT N'Conflict/DeadLetter/Synced→Pending: ' + CAST(@@ROWCOUNT AS nvarchar(20));

-- Ensure at least Head rows for live cloud-zone IDs are Pending (touch if trigger exists)
IF OBJECT_ID(N'dbo.tr_SyncOutbox_PurchaseHead', N'TR') IS NOT NULL
BEGIN
    UPDATE dbo.PurchaseHead SET Remark = ISNULL(Remark, N'') WHERE ID >= 2000000000;
    PRINT N'PurchaseHead touched: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END

SELECT Status, COUNT(*) Cnt,
       SUM(CASE WHEN AttemptCount = 0 THEN 1 ELSE 0 END) AS Attempt0
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Status;

SELECT TOP 20 OutboxID, TableName, Status, AttemptCount, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status = N'Pending'
ORDER BY OutboxID DESC;

PRINT N'Wait 30s with SyncAgent running, then re-check AttemptCount > 0.';
PRINT N'If still Attempt0: Agent not connected to this Cloud DB / not running.';
GO
