/*
  CLOUD — why Purchase C2L still not on Local (one screen).

  Run on CLOUD (db_*warehouse / site4now). Paste Messages + grids back if still stuck.
*/

SET NOCOUNT ON;

PRINT N'=== DB: ' + DB_NAME() + N' / ' + @@SERVERNAME + N' ===';
IF DB_NAME() IN (N'SB1', N'SB')
    PRINT N'ERROR: This is LOCAL. Run Diagnose_PurchaseC2L_Local.sql on Local instead.';

PRINT N'=== 1) SyncClaimOutboxBatch exists? (Agent needs this on Cloud) ===';
SELECT CASE WHEN OBJECT_ID(N'dbo.SyncClaimOutboxBatch', N'P') IS NULL
            THEN N'MISSING — Agent cannot pull C2L'
            ELSE N'OK' END AS ClaimProc;

PRINT N'=== 2) Purchase SyncConfig (need CaptureCloud=1) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

PRINT N'=== 3) Cloud-zone PurchaseHead ===';
SELECT ID, ISNULL(Deleted,0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;

PRINT N'=== 4) C2L outbox status (Purchase) ===';
SELECT Status, COUNT(*) AS Cnt, MIN(CreatedAt) AS Oldest, MAX(CreatedAt) AS Newest,
       SUM(CASE WHEN AttemptCount = 0 THEN 1 ELSE 0 END) AS Attempt0,
       SUM(CASE WHEN AttemptCount > 0 THEN 1 ELSE 0 END) AS Attempted
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Status ORDER BY Status;

PRINT N'=== 5) Recent Purchase C2L rows (look at Status + LastError) ===';
SELECT TOP 30 OutboxID, TableName, Status, AttemptCount, PrimaryKeyJson,
       LEFT(ISNULL(LastError, N''), 160) AS LastError, CreatedAt, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY OutboxID DESC;

PRINT N'=== 6) Stuck Syncing older than 2 minutes ===';
SELECT OutboxID, TableName, PrimaryKeyJson, AttemptCount, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND Status = N'Syncing'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND CreatedAt < DATEADD(minute, -2, SYSUTCDATETIME());

PRINT N'';
PRINT N'VERDICT:';
PRINT N'  Pending + AttemptCount=0 for >1 min → SyncAgent NOT pulling C2L (start/restart Agent).';
PRINT N'  Conflict + LastError LocalWins → run LOCAL LocalWinsUnblock, then reset Conflict→Pending.';
PRINT N'  Synced but Local missing → old Agent bug; run Generate_PurchaseC2L_ApplyOnLocal.sql';
PRINT N'  ClaimProc MISSING → run DataSync_03_ApplyInbound.sql on CLOUD.';
GO
