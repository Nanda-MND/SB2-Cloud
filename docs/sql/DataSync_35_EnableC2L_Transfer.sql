/*
  CLOUD ONLY — Enable C2L capture for TransferHead + TransferDetail.

  Symptom: Cloud Transfer ID >= 2e9 exists, Local top ID still ~8xxx (C2L not running).
  Sale C2L (DataSync_32) does NOT enable Transfer — run this separately.

  Prerequisites:
    1) Cloud_Reseed_TransactionIdRanges.sql (Transfer in cloud zone)
    2) DataSync_28_EnableC2L_Capture.sql once (dbo.SyncInstall_CloudCapture)
    3) Local SyncApply_Generic already installed
    4) Do NOT run on Local

  After enable: touch existing Cloud transfer OR save a new one → Agent → Local.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT '=== ' + DB_NAME() + ' — Enable Transfer C2L (CLOUD) ===';

IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
BEGIN
    RAISERROR(N'Missing SyncInstall_CloudCapture. Run DataSync_28_EnableC2L_Capture.sql on Cloud first.', 16, 1);
    RETURN;
END

DECLARE @floor bigint = 2000000000;
DECLARE @h numeric(38,0) = IDENT_CURRENT(N'dbo.TransferHead');
DECLARE @d numeric(38,0) = IDENT_CURRENT(N'dbo.TransferDetail');

IF @h IS NULL OR @d IS NULL
BEGIN
    RAISERROR(N'TransferHead/TransferDetail missing or has no identity.', 16, 1);
    RETURN;
END

IF @h < @floor - 1 OR @d < @floor - 1
BEGIN
    RAISERROR(N'Transfer identity below Cloud floor — run Cloud_Reseed_TransactionIdRanges.sql first.', 16, 1);
    RETURN;
END

PRINT 'Identity OK TransferHead=' + CAST(@h AS nvarchar(30)) + N' TransferDetail=' + CAST(@d AS nvarchar(30));
GO

EXEC dbo.SyncInstall_CloudCapture @TableName = N'TransferHead';
EXEC dbo.SyncInstall_CloudCapture @TableName = N'TransferDetail';
GO

UPDATE dbo.SyncConfig
SET IsEnabled = 1,
    CaptureCloud = 1,
    CaptureLocal = 0,
    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | Transfer C2L on ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHERE TableName IN (N'TransferHead', N'TransferDetail');

IF @@ROWCOUNT < 2
    PRINT 'WARN: SyncConfig rows missing for Transfer — check SyncConfig.';
ELSE
    PRINT 'SyncConfig TransferHead/TransferDetail: CaptureCloud=1, CaptureLocal=0, IsEnabled=1';
GO

PRINT '=== Verify ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig
WHERE TableName IN (N'TransferHead', N'TransferDetail')
ORDER BY TableName;

SELECT name AS TriggerName, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_TransferHead', N'tr_SyncOutbox_TransferDetail')
ORDER BY name;

PRINT '';
PRINT 'Queue existing Cloud transfer (example ID 2000000000) into outbox:';
PRINT '  UPDATE dbo.TransferHead SET Remark = ISNULL(Remark,N'''') + N'' [C2L]'' WHERE ID = 2000000000;';
PRINT 'LOCAL once: UPDATE dbo.SyncConfig SET IsEnabled=1, CaptureCloud=0 WHERE TableName IN (N''TransferHead'',N''TransferDetail'');';
GO
