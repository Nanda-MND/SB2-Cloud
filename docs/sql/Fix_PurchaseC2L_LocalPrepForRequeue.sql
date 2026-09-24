/*
  LOCAL SB1 — prep before Cloud requeue (Conflict / Synced-but-missing).

  Also prints SyncConflictLog so we see why Conflict had NULL LastError on Cloud.
*/

SET NOCOUNT ON;

PRINT N'=== ' + DB_NAME() + N' ===';
IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%'
BEGIN
    RAISERROR(N'LOCAL only.', 16, 1);
    RETURN;
END
GO

PRINT N'=== SyncConfig (CaptureCloud must be 0) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

UPDATE dbo.SyncConfig
SET IsEnabled = 1, CaptureLocal = 1, CaptureCloud = 0
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');
GO

PRINT N'=== Cancel blocking L2C ===';
UPDATE dbo.SyncOutbox
SET Status = N'Synced',
    LastError = N'Cancelled for C2L retry',
    SyncedAt = SYSUTCDATETIME()
WHERE Direction = N'L2C'
  AND Status IN (N'Pending', N'Syncing')
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');
PRINT N'L2C cancelled: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== Age ALL cloud-zone SyncModifiedAt (force Cloud wins) ===';
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

PRINT N'=== SyncConflictLog (why Conflict) ===';
IF OBJECT_ID(N'dbo.SyncConflictLog', N'U') IS NOT NULL
    SELECT TOP 30 ConflictID, TableName, PrimaryKeyJson, Resolution, DetectedAt,
           LEFT(ISNULL(Message, N''), 150) Msg
    FROM dbo.SyncConflictLog
    WHERE TableName LIKE N'Purchase%'
    ORDER BY ConflictID DESC;
ELSE
    PRINT N'No SyncConflictLog table.';
GO

PRINT N'=== SyncApply_Generic ===';
SELECT CASE
    WHEN OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL THEN N'MISSING'
    WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
         LIKE N'%C2L Applied blocked%' THEN N'OK_HAS_MISSING_CHECK'
    ELSE N'OLD — redeploy DataSync_10_SyncApply_Generic.sql'
END AS ApplyVer;

PRINT N'=== Local cloud-zone IDs now ===';
SELECT ID, Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;

PRINT N'';
PRINT N'NEXT: redeploy DataSync_10 if OLD, then CLOUD Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql';
PRINT N'Then restart SyncAgent.';
PRINT N'IMPORTANT: Agent DBConnection.ini Initial Catalog must be SB1 (this DB).';
GO
