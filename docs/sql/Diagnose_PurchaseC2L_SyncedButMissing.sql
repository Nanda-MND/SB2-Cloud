/*
  LOCAL — Diagnose why C2L Purchase shows Synced on Cloud but row missing on Local.

  Local CaptureCloud=0 is CORRECT (Agent pulls Cloud outbox → SyncApply on Local).
  Do NOT set CaptureCloud=1 on Local for C2L.
*/

SET NOCOUNT ON;

PRINT '=== 1. Local cloud-zone rows (expect Head+Detail if C2L applied) ===';
SELECT ID, Date, AutoID, UserID, Remark, ISNULL(Deleted,0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000
ORDER BY ID;

SELECT ID, RefID, Sr, CodeID, Qty, UnitID, ISNULL(Deleted,0) AS Deleted, SyncOrigin
FROM dbo.PurchaseDetail WHERE RefID >= 2000000000 OR ID >= 2000000000
ORDER BY RefID, ID;

PRINT '=== 2. Local SyncConfig (CaptureCloud must stay 0; IsEnabled=1) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

PRINT '=== 3. Which apply proc exists? ===';
SELECT name FROM sys.procedures
WHERE name IN (N'SyncApply_Generic', N'SyncApply_PurchaseHead', N'SyncApply_PurchaseDetail');

PRINT '=== 4. Conflict / dead letter on Local ===';
IF OBJECT_ID(N'dbo.SyncConflictLog', N'U') IS NOT NULL
    SELECT TOP 20 ConflictID, TableName, PrimaryKeyJson, Resolution, DetectedAt,
           LEFT(ISNULL(Message, N''), 120) AS Msg
    FROM dbo.SyncConflictLog
    WHERE TableName LIKE N'Purchase%' ORDER BY ConflictID DESC;
IF OBJECT_ID(N'dbo.SyncDeadLetter', N'U') IS NOT NULL
    SELECT TOP 20 DeadLetterID, TableName, PrimaryKeyJson, LEFT(ISNULL(LastError,N''), 120) Err
    FROM dbo.SyncDeadLetter
    WHERE TableName LIKE N'Purchase%' ORDER BY DeadLetterID DESC;

PRINT '=== 5. Pending L2C that blocks C2L ===';
SELECT TOP 20 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status IN (N'Pending', N'Syncing')
ORDER BY OutboxID DESC;

PRINT '=== 6. SyncApply version ===';
SELECT CASE
    WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
         LIKE N'%Soft-deleted Local zombie%' THEN N'NEW_SOFTDELETE_EXCEPTION'
    WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
         LIKE N'%C2L Applied blocked%' THEN N'NEW_OK_NO_SOFTDELETE_EXCEPTION'
    ELSE N'OLD — redeploy DataSync_10_SyncApply_Generic.sql'
END AS SyncApplyVer;
GO

/*
  Fix pack (preferred):
    LOCAL:  Fix_PurchaseC2L_LocalWinsUnblock.sql
    CLOUD:  Fix_PurchaseC2L_CloudRetry.sql
    LOCAL:  DataSync_10_SyncApply_Generic.sql  (optional but recommended)

  Manual CLOUD retry only:
UPDATE dbo.SyncOutbox
SET Status = N'Pending', AttemptCount = 0, LastError = NULL, SyncedAt = NULL
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status IN (N'Conflict', N'DeadLetter', N'Synced')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');
*/
GO
