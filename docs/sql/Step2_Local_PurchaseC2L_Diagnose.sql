/*
  ============================================================================
  STEP 2 — LOCAL ONLY diagnose (Purchase C2L)
  ============================================================================
  Database: SB1  (NOT Cloud warehouse)

  Run after Step 1 Cloud showed:
    CaptureCloud=1, triggers OK, Agent pulls (Synced/Conflict with AttemptCount>0)

  Cloud is healthy. Now check why Local does not show IDs 2000000002+.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'STEP 2 LOCAL Purchase C2L diagnose';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME + N'  Utc=' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126);
PRINT N'============================================================';

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%'
BEGIN
    RAISERROR(N'STOP: this is CLOUD. Connect to LOCAL SB1.', 16, 1);
    RETURN;
END
GO

PRINT N'--- A) SyncApply_Generic ---';
SELECT
    CASE WHEN OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
         THEN N'MISSING — run DataSync_10_SyncApply_Generic.sql'
         ELSE N'OK' END AS ApplyProc,
    CASE
        -- Require isCloudZonePk (NOT bare 2000000000 — identity-floor alone false-positives).
        WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
             LIKE N'%isCloudZonePk%'
            THEN N'HAS_CLOUDZONE_BYPASS'
        WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
             LIKE N'%C2L Applied blocked%'
            THEN N'HAS_MISSING_CHECK_NO_CLOUDZONE'
        ELSE N'OLD_OR_UNKNOWN'
    END AS ApplyVer;
GO

PRINT N'--- B) SyncConfig (need IsEnabled=1, CaptureCloud=0, CaptureLocal=1) ---';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY TableName;
GO

PRINT N'--- C) Local cloud-zone PurchaseHead (compare to Cloud 2000000000..4) ---';
SELECT ID, Date, AutoID, ISNULL(Deleted,0) AS Deleted,
       SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID;

SELECT
    (SELECT COUNT(*) FROM dbo.PurchaseHead WHERE ID >= 2000000000) AS LocalCloudHeadCnt,
    (SELECT COUNT(*) FROM dbo.PurchaseDetail WHERE RefID >= 2000000000 OR ID >= 2000000000) AS LocalCloudDetailCnt;
GO

PRINT N'--- D) Missing vs expected Cloud Heads (0..4) ---';
;WITH expected AS (
    SELECT CAST(v AS bigint) AS ID
    FROM (VALUES (2000000000),(2000000001),(2000000002),(2000000003),(2000000004)) x(v)
)
SELECT e.ID AS ExpectedId,
       CASE WHEN h.ID IS NULL THEN N'MISSING_ON_LOCAL'
            WHEN ISNULL(h.Deleted,0) <> 0 THEN N'PRESENT_BUT_DELETED'
            ELSE N'PRESENT_OK'
       END AS LocalVerdict,
       h.SyncOrigin, h.SyncModifiedAt, h.Deleted
FROM expected e
LEFT JOIN dbo.PurchaseHead h ON h.ID = e.ID
ORDER BY e.ID;
GO

PRINT N'--- E) Blocking Pending L2C on Local ---';
SELECT TOP 30 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt,
       LEFT(ISNULL(LastError,N''), 100) AS LastError
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND Status IN (N'Pending', N'Syncing')
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%')
ORDER BY OutboxID DESC;

SELECT COUNT(*) AS BlockingL2CCnt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND Status IN (N'Pending', N'Syncing')
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');
GO

PRINT N'--- F) Wrong C2L outbox on Local (should be 0) ---';
SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Status;
GO

PRINT N'--- G) SyncConflictLog (LocalWins reason) ---';
IF OBJECT_ID(N'dbo.SyncConflictLog', N'U') IS NOT NULL
    SELECT TOP 30 ConflictID, TableName, PrimaryKeyJson, Resolution, DetectedAt,
           LEFT(ISNULL(Message, N''), 160) AS Msg
    FROM dbo.SyncConflictLog
    WHERE TableName LIKE N'Purchase%'
    ORDER BY ConflictID DESC;
ELSE
    PRINT N'No SyncConflictLog table.';
GO

PRINT N'--- H) IDENTITY floor (Local should stay BELOW 2e9 for new local inserts) ---';
SELECT IDENT_CURRENT(N'dbo.PurchaseHead') AS HeadIdent,
       IDENT_CURRENT(N'dbo.PurchaseDetail') AS DetailIdent,
       (SELECT MAX(ID) FROM dbo.PurchaseHead WHERE ID < 2000000000) AS MaxLocalZoneHead;
GO

PRINT N'============================================================';
PRINT N'VERDICT GUIDE (Local):';
PRINT N'  MISSING_ON_LOCAL + Cloud MARKED_SYNCED → Apply failed silently OR old SyncApply; redeploy DataSync_10 + requeue Cloud';
PRINT N'  PRESENT_BUT_DELETED                    → LocalWins soft-delete; LocalWinsUnblock + Cloud requeue';
PRINT N'  BlockingL2CCnt > 0                     → cancel those L2C Pending then Cloud requeue';
PRINT N'  CaptureCloud=1 on Local                → Fix_PurchaseC2L_LocalAfterWrongCloudRun.sql';
PRINT N'  ApplyProc MISSING / OLD                → DataSync_10_SyncApply_Generic.sql';
PRINT N'============================================================';
PRINT N'Paste results. Next we apply only the matching Local fix.';
GO
