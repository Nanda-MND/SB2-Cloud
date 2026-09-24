/*
  Cloud sync status — run on LOCAL (Server\SB1 / SB1)
  sqlcmd -S Server\SB1 -d SB1 -U sa -P YOUR_PASSWORD -C -I -i Check-SyncStatus.sql
*/

SET NOCOUNT ON;

PRINT '=== 1. Outbox summary (L2C) ===';
SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
GROUP BY Status
ORDER BY Status;

PRINT '=== 2. By table ===';
SELECT
    TableName,
    SUM(CASE WHEN Status = N'Pending'  THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN Status = N'Syncing'  THEN 1 ELSE 0 END) AS Syncing,
    SUM(CASE WHEN Status = N'Synced'   THEN 1 ELSE 0 END) AS Synced,
    SUM(CASE WHEN Status = N'DeadLetter' THEN 1 ELSE 0 END) AS DeadLetter
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
GROUP BY TableName
ORDER BY Pending DESC, TableName;

PRINT '=== 3. Recent errors ===';
SELECT TOP 15 OutboxID, TableName, Status, AttemptCount,
       LEFT(LastError, 120) AS LastError, CreatedAt
FROM dbo.SyncOutbox
WHERE LastError IS NOT NULL
ORDER BY OutboxID DESC;

PRINT '=== 4. Agent / Cloud state ===';
SELECT StateKey, StateValue, UpdatedAt
FROM dbo.SyncState
ORDER BY StateKey;

PRINT '=== 5. Enabled tables without outbox (need seed?) ===';
SELECT c.TableName, c.Priority
FROM dbo.SyncConfig c
WHERE c.IsEnabled = 1 AND c.CaptureLocal = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.SyncOutbox o
      WHERE o.Direction = N'L2C' AND o.TableName = c.TableName
  )
ORDER BY c.Priority, c.TableName;

PRINT '=== 6. Key row counts (Local outbox progress) ===';
SELECT c.TableName,
       ISNULL(o.Synced, 0) AS Synced,
       ISNULL(o.Pending, 0) AS Pending
FROM (VALUES
    (N'Setting'), (N'Customer'), (N'SaleHead'), (N'SaleDetail'),
    (N'RawIssueHead'), (N'FinishGoodsHead'), (N'Branch'), (N'Stock')
) v(TableName)
LEFT JOIN dbo.SyncConfig c ON c.TableName = v.TableName
LEFT JOIN (
    SELECT TableName,
           SUM(CASE WHEN Status = N'Synced' THEN 1 ELSE 0 END) AS Synced,
           SUM(CASE WHEN Status = N'Pending' THEN 1 ELSE 0 END) AS Pending
    FROM dbo.SyncOutbox WHERE Direction = N'L2C'
    GROUP BY TableName
) o ON o.TableName = v.TableName;

PRINT '=== 7. Overall ===';
SELECT
    CASE WHEN EXISTS (
        SELECT 1 FROM dbo.SyncOutbox
        WHERE Direction = N'L2C' AND Status IN (N'Pending', N'Syncing')
    ) THEN N'IN PROGRESS' ELSE N'QUEUE EMPTY' END AS SyncQueue,
    (SELECT COUNT(*) FROM dbo.SyncConfig WHERE IsEnabled = 1) AS EnabledTables,
    (SELECT COUNT(*) FROM sys.triggers WHERE name LIKE N'tr_SyncOutbox_%') AS OutboxTriggers;
GO
