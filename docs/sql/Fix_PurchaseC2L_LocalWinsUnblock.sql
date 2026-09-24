/*
  LOCAL SB1 ONLY — unblock Cloud Purchase → Local (C2L) when LocalWinsSkipped.

  Symptom:
    Cloud Purchase exists (ID >= 2e9) but Local missing / stays soft-deleted.
    SyncConflictLog.Resolution = LocalWinsSkipped
      "Local row is newer; cloud change skipped."

  Note:
    PurchaseHead uses column Deleted (and often IsDeleted).
    PurchaseDetail has IsDeleted only — NO Deleted column (Msg 207 if referenced).

  Then CLOUD: Fix_PurchaseC2L_CloudForceEnqueue.sql (or CloudRetry) + SyncAgent.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== ' + DB_NAME() + N' — Purchase C2L LocalWins unblock (LOCAL) ===';

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe78%' OR DB_NAME() LIKE N'%abbe%'
BEGIN
    RAISERROR(N'This script is for LOCAL SB1 only — do not run on Cloud.', 16, 1);
    RETURN;
END
GO

PRINT N'=== 0) BEFORE — cloud-zone Purchase + recent conflicts ===';
-- PurchaseHead has Deleted (+ often IsDeleted). PurchaseDetail has IsDeleted only.
SELECT ID, Date, AutoID, ISNULL(Deleted, 0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID;

-- PurchaseDetail: IsDeleted only (no Deleted). Dynamic SQL avoids Msg 207 compile bind.
DECLARE @d nvarchar(max) = N'
SELECT ID, RefID, Sr, SyncOrigin, SyncModifiedAt';
IF COL_LENGTH(N'dbo.PurchaseDetail', N'IsDeleted') IS NOT NULL
    SET @d = N'
SELECT ID, RefID, Sr, ISNULL(IsDeleted, 0) AS IsDeleted, SyncOrigin, SyncModifiedAt';
SET @d += N'
FROM dbo.PurchaseDetail
WHERE RefID >= 2000000000 OR ID >= 2000000000
ORDER BY RefID, ID';
EXEC sp_executesql @d;

IF OBJECT_ID(N'dbo.SyncConflictLog', N'U') IS NOT NULL
    SELECT TOP 30 ConflictID, TableName, PrimaryKeyJson, Resolution, DetectedAt,
           LEFT(ISNULL(Message, N''), 120) AS Msg
    FROM dbo.SyncConflictLog
    WHERE TableName LIKE N'Purchase%'
    ORDER BY ConflictID DESC;
GO

PRINT N'=== 1) SyncConfig — IsEnabled=1, CaptureCloud=0, CaptureLocal=1 ===';
UPDATE dbo.SyncConfig
SET IsEnabled = 1,
    CaptureCloud = 0,
    CaptureLocal = 1,
    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | Purchase C2L unblock ',
                        CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');
GO

PRINT N'=== 2) Cancel Pending/Syncing L2C that blocks C2L for cloud-zone Purchase ===';
UPDATE dbo.SyncOutbox
SET Status = N'Synced',
    LastError = N'Cancelled: unblock C2L Purchase LocalWins (cloud-zone PK)',
    SyncedAt = SYSUTCDATETIME()
WHERE Direction = N'L2C'
  AND Status IN (N'Pending', N'Syncing')
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (
        PrimaryKeyJson LIKE N'%"ID":2%'
     OR PrimaryKeyJson LIKE N'%200000000%'
      );

PRINT N'L2C outbox cancelled: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== 3) Age SyncModifiedAt so Cloud C2L is not LocalWins-skipped ===';
-- Head: soft-deleted via Deleted and/or IsDeleted
DECLARE @sql nvarchar(max);

IF COL_LENGTH(N'dbo.PurchaseHead', N'SyncModifiedAt') IS NOT NULL
BEGIN
    SET @sql = N'
UPDATE dbo.PurchaseHead
SET SyncModifiedAt = DATEADD(day, -30, SYSUTCDATETIME())
WHERE ID >= 2000000000
  AND (1=0';
    IF COL_LENGTH(N'dbo.PurchaseHead', N'Deleted') IS NOT NULL
        SET @sql += N' OR ISNULL(Deleted,0) <> 0';
    IF COL_LENGTH(N'dbo.PurchaseHead', N'IsDeleted') IS NOT NULL
        SET @sql += N' OR ISNULL(IsDeleted,0) <> 0';
    -- Also age any cloud-origin row so stuck LocalWins clears for missing updates
    SET @sql += N' OR ISNULL(SyncOrigin,0) = 2)';
    EXEC sp_executesql @sql;
    PRINT N'PurchaseHead aged: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END

-- Detail: IsDeleted only (Msg 207 if using Deleted)
IF COL_LENGTH(N'dbo.PurchaseDetail', N'SyncModifiedAt') IS NOT NULL
BEGIN
    SET @sql = N'
UPDATE dbo.PurchaseDetail
SET SyncModifiedAt = DATEADD(day, -30, SYSUTCDATETIME())
WHERE (RefID >= 2000000000 OR ID >= 2000000000)
  AND (1=0';
    IF COL_LENGTH(N'dbo.PurchaseDetail', N'IsDeleted') IS NOT NULL
        SET @sql += N' OR ISNULL(IsDeleted,0) <> 0';
    IF COL_LENGTH(N'dbo.PurchaseDetail', N'Deleted') IS NOT NULL
        SET @sql += N' OR ISNULL(Deleted,0) <> 0';
    SET @sql += N' OR ISNULL(SyncOrigin,0) = 2)';
    EXEC sp_executesql @sql;
    PRINT N'PurchaseDetail aged: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END
GO

PRINT N'=== 4) SyncApply_Generic version (redeploy DataSync_10 if OLD) ===';
SELECT CASE
    WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
         LIKE N'%Soft-deleted Local zombie%' THEN N'NEW_SOFTDELETE_EXCEPTION'
    WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
         LIKE N'%C2L Applied blocked%' THEN N'NEW_OK_NO_SOFTDELETE_EXCEPTION'
    ELSE N'OLD_MISSING_CHECK — run DataSync_10_SyncApply_Generic.sql on LOCAL'
END AS SyncApplyVer;
GO

PRINT N'=== AFTER ===';
SELECT ID, ISNULL(Deleted, 0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;

PRINT N'';
PRINT N'NEXT: Cloud → Fix_PurchaseC2L_CloudForceEnqueue.sql';
PRINT N'Then wait for SyncAgent C2L pull.';
PRINT N'Optional LOCAL: redeploy docs/sql/DataSync_10_SyncApply_Generic.sql';
PRINT N'Verify: SELECT ID, SyncOrigin FROM PurchaseHead WHERE ID >= 2000000000;';
GO
