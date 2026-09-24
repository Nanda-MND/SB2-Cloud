/*
  ============================================================================
  STEP 3a — LOCAL SB1 prep (after Step 2 verdict)
  ============================================================================
  Step 2 showed:
    ApplyProc OK but ConflictLog "Local PurchaseHead is newer" (OLD LocalWins text)
    IDs 2000000002..4 MISSING_ON_LOCAL
    CaptureLocal=1 CaptureCloud=0 OK
    BlockingL2CCnt=0

  BEFORE this script: run DataSync_10_SyncApply_Generic.sql on LOCAL
  so SyncApply has isCloudZonePk (real cloud-zone LocalWins bypass).
  Step2 "HAS_CLOUDZONE_BYPASS" can false-positive on IDENTITY floor 2e9 alone.

  AFTER this script: Cloud → Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'STEP 3a LOCAL Prep — Purchase C2L';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME;
PRINT N'============================================================';

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%'
BEGIN
    RAISERROR(N'STOP: CLOUD DB. Run on LOCAL SB1 only.', 16, 1);
    RETURN;
END
GO

PRINT N'--- A) SyncApply must contain isCloudZonePk ---';
IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    RAISERROR(N'STOP: SyncApply_Generic missing. Run DataSync_10_SyncApply_Generic.sql first.', 16, 1);
    RETURN;
END

IF OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) NOT LIKE N'%isCloudZonePk%'
BEGIN
    RAISERROR(N'STOP: SyncApply lacks isCloudZonePk. Run DataSync_10_SyncApply_Generic.sql on LOCAL first, then re-run this script.', 16, 1);
    RETURN;
END

SELECT N'OK_HAS_isCloudZonePk' AS ApplyVer,
       CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
                 LIKE N'%C2L Applied blocked%'
            THEN N'OK_HAS_MISSING_CHECK' ELSE N'MISSING_CHECK_WEAK' END AS PostApplyCheck;
GO

PRINT N'--- B) SyncConfig (force Local L2C / no Cloud capture) ---';
UPDATE dbo.SyncConfig
SET IsEnabled = 1, CaptureLocal = 1, CaptureCloud = 0,
    Notes = LEFT(CONCAT(N'Step3a LocalPrep ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126),
                        N' | ', ISNULL(Notes, N'')), 500)
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');
GO

PRINT N'--- C) Cancel blocking L2C (cloud-zone keys) ---';
UPDATE dbo.SyncOutbox
SET Status = N'Synced',
    LastError = N'Cancelled Step3a for C2L requeue',
    SyncedAt = SYSUTCDATETIME()
WHERE Direction = N'L2C'
  AND Status IN (N'Pending', N'Syncing')
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');
PRINT N'L2C cancelled: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'--- D) Age Local cloud-zone clocks (Cloud must win timestamp) ---';
UPDATE dbo.PurchaseHead
SET SyncModifiedAt = DATEADD(day, -30, SYSUTCDATETIME())
WHERE ID >= 2000000000;
PRINT N'Head aged: ' + CAST(@@ROWCOUNT AS nvarchar(20));

IF COL_LENGTH(N'dbo.PurchaseDetail', N'SyncModifiedAt') IS NOT NULL
BEGIN
    DECLARE @s nvarchar(max) = N'
UPDATE dbo.PurchaseDetail
SET SyncModifiedAt = DATEADD(day, -30, SYSUTCDATETIME())
WHERE ID >= 2000000000 OR RefID >= 2000000000';
    EXEC sp_executesql @s;
    PRINT N'Detail aged: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END
GO

PRINT N'--- E) Local cloud-zone now ---';
SELECT ID, ISNULL(Deleted,0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;
GO

PRINT N'============================================================';
PRINT N'NEXT (CLOUD warehouse only):';
PRINT N'  docs/sql/Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql';
PRINT N'Then keep SyncAgent running.';
PRINT N'VERIFY on LOCAL:';
PRINT N'  SELECT ID FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;';
PRINT N'Expect 2000000000..2000000004';
PRINT N'============================================================';
GO
