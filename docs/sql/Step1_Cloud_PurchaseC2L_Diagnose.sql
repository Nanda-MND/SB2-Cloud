/*
  ============================================================================
  STEP 1 — CLOUD ONLY diagnose (Purchase C2L)
  ============================================================================
  Database: db_*warehouse / site4now   (NOT SB1)

  Run entire script. Send back:
    - Messages tab text
    - Each Results grid (or screenshot)

  Do not run Local scripts until Cloud verdict is GREEN.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'STEP 1 CLOUD Purchase C2L diagnose';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME + N'  Utc=' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126);
PRINT N'============================================================';

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'STOP: this is LOCAL SB1. Connect to Cloud warehouse DB first.', 16, 1);
    RETURN;
END
GO

/* ----- A) Identity / cloud-zone floor ----- */
PRINT N'--- A) Purchase identity (expect IDENT_CURRENT >= 2000000000) ---';
SELECT
    IDENT_CURRENT(N'dbo.PurchaseHead')   AS HeadIdent,
    IDENT_CURRENT(N'dbo.PurchaseDetail') AS DetailIdent,
    (SELECT MAX(ID) FROM dbo.PurchaseHead WHERE ID >= 2000000000) AS MaxCloudHeadId,
    (SELECT COUNT(*) FROM dbo.PurchaseHead WHERE ID >= 2000000000) AS CloudHeadCnt,
    (SELECT COUNT(*) FROM dbo.PurchaseDetail WHERE RefID >= 2000000000 OR ID >= 2000000000) AS CloudDetailCnt;
GO

/* ----- B) Live cloud-zone rows ----- */
PRINT N'--- B) PurchaseHead cloud-zone rows ---';
SELECT ID, Date, AutoID, ISNULL(Deleted,0) AS Deleted,
       SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID;

PRINT N'--- B2) PurchaseDetail counts per RefID ---';
SELECT RefID, COUNT(*) AS LineCnt,
       MIN(ID) AS MinDetailId, MAX(ID) AS MaxDetailId
FROM dbo.PurchaseDetail
WHERE RefID >= 2000000000
GROUP BY RefID
ORDER BY RefID;
GO

/* ----- C) SyncConfig ----- */
PRINT N'--- C) SyncConfig (need IsEnabled=1, CaptureCloud=1, CaptureLocal=0) ---';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority, Notes
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY TableName;
GO

/* ----- D) Triggers ----- */
PRINT N'--- D) Outbox triggers on Purchase ---';
SELECT tr.name AS TriggerName,
       OBJECT_NAME(tr.parent_id) AS ParentTable,
       tr.is_disabled,
       CASE
         WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%''C2L''%' THEN N'writes C2L'
         WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%''L2C''%' THEN N'writes L2C (WRONG on Cloud)'
         ELSE N'unknown'
       END AS DirectionHint,
       CASE
         WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%CaptureCloud%1%' THEN N'checks CaptureCloud'
         WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%CaptureLocal%1%' THEN N'checks CaptureLocal (bad on Cloud)'
         ELSE N'?'
       END AS CaptureHint
FROM sys.triggers tr
WHERE OBJECT_NAME(tr.parent_id) IN (N'PurchaseHead', N'PurchaseDetail')
  AND tr.name LIKE N'%SyncOutbox%'
ORDER BY ParentTable, TriggerName;

SELECT CASE WHEN OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
            THEN N'MISSING'
            ELSE N'OK' END AS SyncInstall_CloudCapture;
GO

/* ----- E) Claim proc (Agent needs this) ----- */
PRINT N'--- E) SyncClaimOutboxBatch ---';
SELECT CASE WHEN OBJECT_ID(N'dbo.SyncClaimOutboxBatch', N'P') IS NULL
            THEN N'MISSING — Agent cannot pull'
            ELSE N'OK' END AS ClaimProc;
GO

/* ----- F) Outbox summary ----- */
PRINT N'--- F) Purchase outbox by Direction/Status ---';
SELECT Direction, Status, COUNT(*) AS Cnt,
       SUM(CASE WHEN AttemptCount = 0 THEN 1 ELSE 0 END) AS Attempt0,
       SUM(CASE WHEN AttemptCount > 0 THEN 1 ELSE 0 END) AS Attempted,
       MIN(CreatedAt) AS Oldest,
       MAX(CreatedAt) AS Newest
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Direction, Status
ORDER BY Direction, Status;
GO

/* ----- G) Recent C2L rows (the ones Agent should pull) ----- */
PRINT N'--- G) Latest 40 C2L Purchase outbox rows ---';
SELECT TOP 40
    OutboxID, TableName, Status, AttemptCount,
    PrimaryKeyJson,
    SyncModifiedAt AS OutboxModAt,
    CreatedAt, SyncedAt,
    LEFT(ISNULL(LastError, N''), 120) AS LastError
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY OutboxID DESC;
GO

/* ----- H) Per Head ID: is there C2L outbox? ----- */
PRINT N'--- H) Each cloud Head ID vs latest C2L Head outbox ---';
;WITH heads AS (
    SELECT ID FROM dbo.PurchaseHead WHERE ID >= 2000000000
),
ob AS (
    SELECT
        TRY_CAST(JSON_VALUE(PrimaryKeyJson, '$.ID') AS bigint) AS ID,
        OutboxID, Status, AttemptCount, LastError, CreatedAt, SyncedAt,
        ROW_NUMBER() OVER (
            PARTITION BY TRY_CAST(JSON_VALUE(PrimaryKeyJson, '$.ID') AS bigint)
            ORDER BY OutboxID DESC
        ) AS rn
    FROM dbo.SyncOutbox
    WHERE Direction = N'C2L'
      AND TableName = N'PurchaseHead'
      AND PrimaryKeyJson LIKE N'%200000000%'
)
SELECT h.ID AS HeadId,
       ob.OutboxID, ob.Status, ob.AttemptCount,
       LEFT(ISNULL(ob.LastError, N''), 100) AS LastError,
       ob.CreatedAt, ob.SyncedAt,
       CASE
         WHEN ob.OutboxID IS NULL THEN N'NO_OUTBOX'
         WHEN ob.Status = N'Pending' AND ob.AttemptCount = 0 THEN N'PENDING_NOT_PULLED'
         WHEN ob.Status = N'Pending' AND ob.AttemptCount > 0 THEN N'PENDING_RETRY'
         WHEN ob.Status = N'Conflict' THEN N'CONFLICT_LOCALWINS'
         WHEN ob.Status = N'Synced' THEN N'MARKED_SYNCED'
         WHEN ob.Status = N'DeadLetter' THEN N'DEADLETTER'
         ELSE ob.Status
       END AS Verdict
FROM heads h
LEFT JOIN ob ON ob.ID = h.ID AND ob.rn = 1
ORDER BY h.ID;
GO

/* ----- I) Smoke: can a touch create Pending? (optional — only if Capture OK) ----- */
PRINT N'--- I) Optional touch smoke (Head ID = MAX cloud) ---';
DECLARE @maxId bigint = (SELECT MAX(ID) FROM dbo.PurchaseHead WHERE ID >= 2000000000);
IF @maxId IS NOT NULL
BEGIN
    DECLARE @before int = (
        SELECT COUNT(*) FROM dbo.SyncOutbox
        WHERE Direction = N'C2L' AND TableName = N'PurchaseHead'
          AND Status = N'Pending'
          AND PrimaryKeyJson LIKE N'%"ID":' + CAST(@maxId AS nvarchar(20)) + N'%'
    );

    UPDATE dbo.PurchaseHead
    SET Remark = ISNULL(Remark, N'')
    WHERE ID = @maxId;

    DECLARE @after int = (
        SELECT COUNT(*) FROM dbo.SyncOutbox
        WHERE Direction = N'C2L' AND TableName = N'PurchaseHead'
          AND Status = N'Pending'
          AND PrimaryKeyJson LIKE N'%"ID":' + CAST(@maxId AS nvarchar(20)) + N'%'
    );

    SELECT @maxId AS TouchedHeadId, @before AS PendingBefore, @after AS PendingAfter,
           CASE WHEN @after > @before THEN N'TRIGGER_OK_NEW_PENDING'
                WHEN @after = @before AND @after > 0 THEN N'PENDING_ALREADY_EXISTS'
                ELSE N'TRIGGER_DID_NOT_ENQUEUE'
           END AS TouchVerdict;
END
ELSE
    PRINT N'No cloud-zone PurchaseHead — nothing to touch.';
GO

PRINT N'============================================================';
PRINT N'VERDICT GUIDE (Cloud only):';
PRINT N'  CaptureCloud<>1 or wrong trigger     → fix SyncConfig / DataSync_28 + 36';
PRINT N'  NO_OUTBOX for a Head ID              → capture broken; run CloudForceEnqueue';
PRINT N'  PENDING_NOT_PULLED (AttemptCount=0)  → SyncAgent not pulling C2L';
PRINT N'  CONFLICT_LOCALWINS                   → next step LOCAL (LocalWins) then requeue';
PRINT N'  MARKED_SYNCED                        → Agent thinks Local has it; check LOCAL next';
PRINT N'  TRIGGER_DID_NOT_ENQUEUE              → CaptureCloud/trigger broken';
PRINT N'============================================================';
PRINT N'Stop here. Paste results. We decide Cloud fix before touching Local.';
GO
