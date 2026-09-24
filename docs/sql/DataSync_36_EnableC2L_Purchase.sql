/*
  CLOUD ONLY — Enable C2L capture for PurchaseHead + PurchaseDetail.

  Symptom: Cloud Purchase ID >= 2e9 exists, Local top still ~8xxx.
  Same as Transfer: Sale C2L does not enable Purchase.

  Prerequisites: Cloud reseed + DataSync_28 (SyncInstall_CloudCapture). Do NOT run on Local.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT '=== ' + DB_NAME() + ' — Enable Purchase C2L (CLOUD) ===';

IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
BEGIN
    RAISERROR(N'Missing SyncInstall_CloudCapture. Run DataSync_28_EnableC2L_Capture.sql on Cloud first.', 16, 1);
    RETURN;
END

DECLARE @floor bigint = 2000000000;
DECLARE @h numeric(38,0) = IDENT_CURRENT(N'dbo.PurchaseHead');
DECLARE @d numeric(38,0) = IDENT_CURRENT(N'dbo.PurchaseDetail');

IF @h IS NULL OR @d IS NULL
BEGIN
    RAISERROR(N'PurchaseHead/PurchaseDetail missing or has no identity.', 16, 1);
    RETURN;
END

IF @h < @floor - 1 OR @d < @floor - 1
BEGIN
    RAISERROR(N'Purchase identity below Cloud floor — run Cloud_Reseed_TransactionIdRanges.sql first.', 16, 1);
    RETURN;
END

PRINT 'Identity OK PurchaseHead=' + CAST(@h AS nvarchar(30)) + N' PurchaseDetail=' + CAST(@d AS nvarchar(30));
GO

EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseHead';
EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseDetail';
GO

UPDATE dbo.SyncConfig
SET IsEnabled = 1,
    CaptureCloud = 1,
    CaptureLocal = 0,
    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | Purchase C2L on ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

IF @@ROWCOUNT < 2
    PRINT 'WARN: SyncConfig rows missing for Purchase.';
ELSE
    PRINT 'SyncConfig PurchaseHead/PurchaseDetail: CaptureCloud=1, CaptureLocal=0, IsEnabled=1';
GO

PRINT '=== Verify ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY TableName;

SELECT name AS TriggerName, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_PurchaseHead', N'tr_SyncOutbox_PurchaseDetail')
ORDER BY name;

PRINT '';
PRINT 'Queue existing Cloud purchase:';
PRINT '  UPDATE dbo.PurchaseHead SET Remark = ISNULL(Remark,N'''') + N'' [C2L]'' WHERE ID = 2000000000;';
PRINT 'LOCAL: UPDATE dbo.SyncConfig SET IsEnabled=1, CaptureCloud=0 WHERE TableName IN (N''PurchaseHead'',N''PurchaseDetail'');';
GO
