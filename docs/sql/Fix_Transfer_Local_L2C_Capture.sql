/*
  ============================================================================
  LOCAL ONLY — TransferDetail Local→Cloud (L2C) not pushing
  ============================================================================
  Prefer the full entry pack (Sale/Purchase/Transfer/IE/…):

      docs/sql/Fix_AllEntry_Local_L2C_Capture.sql

  This file remains as a Transfer-only quick fix.
  ============================================================================
  Symptom:
    Edit TransferDetail on Local, Save — Cloud row unchanged.
    Voucher IDs are Cloud-zone (e.g. 2000000009 / AutoID H260900010).
    Local SyncOrigin = 2 (row arrived via C2L).

  Cause (typical after DataSync_35 Transfer C2L):
    Cloud has CaptureCloud=1 (Cloud→Local OK).
    Local SyncConfig for Transfer has CaptureLocal=0 (or trigger missing)
    → Local UPDATE does not write SyncOutbox L2C → Cloud never updates.

  Run on LOCAL SB1 only. Then re-save the transfer (or touch Detail) and wait for Agent.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== DB: ' + DB_NAME() + N' ===';
PRINT N'=== 1) SyncConfig Transfer (expect CaptureLocal=1, CaptureCloud=0) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName IN (N'TransferHead', N'TransferDetail')
ORDER BY TableName;

PRINT N'=== 2) Outbox triggers ===';
SELECT name AS TriggerName, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_TransferHead', N'tr_SyncOutbox_TransferDetail')
ORDER BY name;

-- Fix config
UPDATE dbo.SyncConfig
SET IsEnabled = 1,
    CaptureLocal = 1,
    CaptureCloud = 0,
    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | Transfer L2C on ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHERE TableName IN (N'TransferHead', N'TransferDetail');

IF @@ROWCOUNT < 2
BEGIN
    -- Insert if missing
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'TransferHead')
        INSERT INTO dbo.SyncConfig
            (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
        VALUES (N'TransferHead', 1, 1, 0, N'ID', 100, 40, N'Transfer L2C');
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'TransferDetail')
        INSERT INTO dbo.SyncConfig
            (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
        VALUES (N'TransferDetail', 1, 1, 0, N'ID', 100, 45, N'Transfer L2C');
END

PRINT N'SyncConfig updated: CaptureLocal=1, CaptureCloud=0';

-- Reinstall L2C capture triggers if SyncInstall_Table exists
IF OBJECT_ID(N'dbo.SyncInstall_Table', N'P') IS NOT NULL
BEGIN
    EXEC dbo.SyncInstall_Table @TableName = N'TransferHead', @InstallCapture = 1;
    EXEC dbo.SyncInstall_Table @TableName = N'TransferDetail', @InstallCapture = 1;
    PRINT N'SyncInstall_Table ran for TransferHead/TransferDetail.';
END
ELSE
BEGIN
    PRINT N'WARN: dbo.SyncInstall_Table missing — ensure tr_SyncOutbox_TransferDetail exists and checks CaptureLocal=1.';
END
GO

PRINT N'=== 3) After fix — config + triggers ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'TransferHead', N'TransferDetail')
ORDER BY TableName;

SELECT name AS TriggerName, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_TransferHead', N'tr_SyncOutbox_TransferDetail')
ORDER BY name;
GO

/*
  === 4) Force re-queue one voucher after fix (example AutoID) ===
  Edit AutoID if needed, then run:

DECLARE @RefID int =
(
    SELECT TOP 1 ID FROM dbo.TransferHead
    WHERE AutoID = N'H260900010' AND ISNULL(Deleted,0) <> 1
);

UPDATE dbo.TransferDetail
SET Remark = ISNULL(Remark, N'')
WHERE RefID = @RefID;

SELECT TOP 20 *
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName IN (N'TransferHead', N'TransferDetail')
  AND Status IN (N'Pending', N'Failed', N'DeadLetter')
ORDER BY ID DESC;

  Expect Pending TransferDetail rows → SyncAgent pushes to Cloud.
*/
GO
