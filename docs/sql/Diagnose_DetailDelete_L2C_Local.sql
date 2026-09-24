/*
  ============================================================================
  LOCAL — diagnose why PurchaseDetail DELETE is not L2C-syncing
  ============================================================================
  Run on SB1 after: Local edit → delete a detail line → Save.
*/

SET NOCOUNT ON;
PRINT N'=== LOCAL Detail-delete L2C diagnose ===';
PRINT N'DB=' + DB_NAME();

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%'
BEGIN
    RAISERROR(N'STOP: Cloud DB. Run on LOCAL SB1.', 16, 1);
    RETURN;
END
GO

PRINT N'--- A) SyncConfig PurchaseDetail (need CaptureLocal=1) ---';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');
GO

PRINT N'--- B) Outbox triggers (Detail must include DELETE) ---';
SELECT tr.name, OBJECT_NAME(tr.parent_id) AS ParentTable, tr.is_disabled,
       CASE WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%DELETE%'
                 AND OBJECT_DEFINITION(tr.object_id) LIKE N'%Operation%=%''D''%'
            THEN N'HAS_PHYSICAL_DELETE_CAPTURE'
            WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%DELETE%'
            THEN N'HAS_DELETE_EVENT'
            ELSE N'MISSING_DELETE_CAPTURE' END AS DeleteCapture
FROM sys.triggers tr
WHERE OBJECT_NAME(tr.parent_id) IN (N'PurchaseHead', N'PurchaseDetail')
  AND tr.name LIKE N'%SyncOutbox%'
ORDER BY ParentTable, tr.name;
GO

PRINT N'--- C) Recent PurchaseDetail outbox (look for Operation=D) ---';
SELECT TOP 40 OutboxID, Operation, Status, AttemptCount, PrimaryKeyJson,
       LEFT(ISNULL(LastError,N''), 120) AS Err,
       CreatedAt, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName = N'PurchaseDetail'
ORDER BY OutboxID DESC;
GO

PRINT N'--- D) Counts by Operation/Status (last 2 days) ---';
SELECT Operation, Status, COUNT(*) Cnt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName = N'PurchaseDetail'
  AND CreatedAt >= DATEADD(day, -2, SYSUTCDATETIME())
GROUP BY Operation, Status
ORDER BY Operation, Status;
GO

PRINT N'=== If no Operation=D rows after a UI detail delete: trigger/capture broken ===';
PRINT N'=== If Operation=D Synced but Cloud still shows line: Cloud SyncApply missing hardDeleteDetail ===';
GO
