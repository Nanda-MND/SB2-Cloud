/*
  LOCAL SB1 — why Cloud Purchase not landing.

  Run on LOCAL only.
*/

SET NOCOUNT ON;

PRINT N'=== DB: ' + DB_NAME() + N' / ' + @@SERVERNAME + N' ===';
IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%'
    PRINT N'ERROR: This looks like CLOUD. Use Diagnose_PurchaseC2L_Cloud.sql instead.';

PRINT N'=== 1) SyncApply_Generic ===';
SELECT CASE WHEN OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
            THEN N'MISSING — run DataSync_10_SyncApply_Generic.sql'
            ELSE N'OK' END AS ApplyProc,
       CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
                 LIKE N'%Soft-deleted Local zombie%'
            THEN N'HAS_SOFTDELETE_EXCEPTION'
            WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
                 LIKE N'%C2L Applied blocked%'
            THEN N'NEW_OK'
            ELSE N'OLD_OR_UNKNOWN' END AS ApplyVer;

PRINT N'=== 2) SyncConfig (MUST CaptureCloud=0, CaptureLocal=1) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

PRINT N'=== 3) Local cloud-zone PurchaseHead (missing IDs = C2L not applied) ===';
SELECT ID, ISNULL(Deleted,0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;

PRINT N'=== 4) Wrong C2L outbox on Local? (should be 0) ===';
SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Status;

PRINT N'=== 5) Pending L2C that blocks C2L apply ===';
SELECT TOP 20 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C' AND Status IN (N'Pending', N'Syncing')
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%')
ORDER BY OutboxID DESC;

PRINT N'';
PRINT N'VERDICT:';
PRINT N'  CaptureCloud=1 → run Fix_PurchaseC2L_LocalAfterWrongCloudRun.sql';
PRINT N'  Soft-deleted / SyncOrigin=2 with old LocalWins → Fix_PurchaseC2L_LocalWinsUnblock.sql';
PRINT N'  ApplyProc MISSING → DataSync_10_SyncApply_Generic.sql';
PRINT N'  IDs missing vs Cloud → Agent pull or Generate_PurchaseC2L_ApplyOnLocal.sql';
GO
