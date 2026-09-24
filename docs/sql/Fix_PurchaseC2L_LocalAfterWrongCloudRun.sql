/*
  LOCAL ONLY — you ran a CLOUD Purchase C2L script on Local by mistake.

  Symptoms after wrong run:
    - SyncConfig CaptureCloud=1 for Purchase (WRONG on Local)
    - SyncOutbox Direction=C2L rows on Local (Agent never claims these from Local)
    - Error: SyncInstall_CloudCapture missing (normal on Local)
    - Local→Cloud (L2C) may stop for Purchase

  This script restores Local to L2C-only for Purchase (+ clears wrong C2L outbox).
  Then run LocalWins unblock if cloud-zone rows are soft-deleted/newer.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== ' + DB_NAME() + N' — Repair Local after Cloud script run by mistake ===';

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe78%'
BEGIN
    RAISERROR(N'This is CLOUD DB. Stop. Use Fix_PurchaseC2L_CloudForceEnqueue.sql on Cloud instead.', 16, 1);
    RETURN;
END
GO

PRINT N'=== BEFORE ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT Direction, Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Direction, Status;
GO

PRINT N'=== 1) Delete wrong C2L outbox on Local ===';
DELETE FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail');
PRINT N'Deleted Local C2L Purchase rows: ' + CAST(@@ROWCOUNT AS nvarchar(20));

-- Safety: any other C2L on Local is also wrong
DELETE FROM dbo.SyncOutbox WHERE Direction = N'C2L';
PRINT N'Deleted all Local C2L rows: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== 2) Purchase SyncConfig → CaptureLocal=1, CaptureCloud=0 ===';
UPDATE dbo.SyncConfig
SET IsEnabled = 1,
    CaptureLocal = 1,
    CaptureCloud = 0,
    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | undo Cloud script ',
                        CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

-- Clear CaptureCloud everywhere on Local (Cloud scripts often flip many tables)
UPDATE dbo.SyncConfig
SET CaptureCloud = 0
WHERE IsEnabled = 1
  AND CaptureCloud = 1
  AND TableName NOT LIKE N'Sync%';

PRINT N'CaptureCloud cleared on Local enabled tables: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== 3) Drop Cloud-only capture helper if installed on Local ===';
IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SyncInstall_CloudCapture;
    PRINT N'Dropped SyncInstall_CloudCapture from Local.';
END
GO

-- Drop C2L triggers that check CaptureCloud on Local Purchase (if any)
DECLARE @drop nvarchar(max) = N'';
SELECT @drop += N'DROP TRIGGER ' + QUOTENAME(SCHEMA_NAME(o.schema_id)) + N'.' + QUOTENAME(tr.name) + N';'
FROM sys.triggers tr
INNER JOIN sys.objects o ON o.object_id = tr.parent_id
WHERE o.name IN (N'PurchaseHead', N'PurchaseDetail')
  AND (
        OBJECT_DEFINITION(tr.object_id) LIKE N'%CaptureCloud%=%1%'
     OR OBJECT_DEFINITION(tr.object_id) LIKE N'%''C2L''%'
      )
  AND tr.name LIKE N'tr_SyncOutbox_%';

IF LEN(@drop) > 0
BEGIN
    PRINT N'Dropping Cloud-style Purchase triggers on Local:';
    PRINT @drop;
    EXEC sp_executesql @drop;
END
GO

-- Reinstall Local L2C capture if helper exists
IF OBJECT_ID(N'dbo.SyncInstall_Table', N'P') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC dbo.SyncInstall_Table @TableName = N'PurchaseHead', @InstallCapture = 1;
        EXEC dbo.SyncInstall_Table @TableName = N'PurchaseDetail', @InstallCapture = 1;
        PRINT N'Reinstalled Local L2C capture for Purchase.';
    END TRY
    BEGIN CATCH
        PRINT N'WARN SyncInstall_Table: ' + ERROR_MESSAGE();
    END CATCH

    UPDATE dbo.SyncConfig
    SET IsEnabled = 1, CaptureLocal = 1, CaptureCloud = 0
    WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');
END
ELSE
    PRINT N'WARN: SyncInstall_Table missing — ensure tr_SyncOutbox_Purchase* check CaptureLocal=1.';
GO

PRINT N'=== AFTER (expect CaptureLocal=1, CaptureCloud=0, no C2L outbox) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT Direction, Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Direction, Status;

SELECT name, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name LIKE N'tr_SyncOutbox_Purchase%';
GO

PRINT N'';
PRINT N'NEXT on LOCAL:';
PRINT N'  1) Fix_PurchaseC2L_LocalWinsUnblock.sql';
PRINT N'  2) DataSync_10_SyncApply_Generic.sql';
PRINT N'THEN on CLOUD only (db_*warehouse):';
PRINT N'  Fix_PurchaseC2L_CloudForceEnqueue.sql';
PRINT N'  -- or: UPDATE SyncOutbox SET Status=N''Pending'', AttemptCount=0, LastError=NULL';
PRINT N'  --    WHERE Direction=N''C2L'' AND TableName LIKE N''Purchase%'' AND Status=N''Conflict'';';
PRINT N'Keep SyncAgent running.';
GO
