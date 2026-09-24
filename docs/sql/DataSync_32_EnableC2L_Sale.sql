/*
  CLOUD ONLY — Enable C2L capture for SaleHead + SaleDetail.

  Prerequisites:
    1) Cloud_Reseed_TransactionIdRanges.sql done (OK_CLOUD_ZONE)
    2) DataSync_28_EnableC2L_Capture.sql once on Cloud (dbo.SyncInstall_CloudCapture)
    3) Local already has SyncApply_Generic (normal agent setup)
    4) Do NOT run on Local; do NOT stop clients / Agent for this step

  sqlcmd ... -d <CloudDB> -i DataSync_32_EnableC2L_Sale.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT '=== ' + DB_NAME() + ' — Enable Sale C2L (CLOUD) ===';

IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
BEGIN
    RAISERROR(N'Missing SyncInstall_CloudCapture. Run DataSync_28_EnableC2L_Capture.sql on Cloud first.', 16, 1);
    RETURN;
END

DECLARE @floor bigint = 2000000000;
DECLARE @h numeric(38,0) = IDENT_CURRENT(N'dbo.SaleHead');
DECLARE @d numeric(38,0) = IDENT_CURRENT(N'dbo.SaleDetail');

IF @h IS NULL OR @d IS NULL
BEGIN
    RAISERROR(N'SaleHead/SaleDetail missing or has no identity.', 16, 1);
    RETURN;
END

IF @h < @floor - 1 OR @d < @floor - 1
BEGIN
    RAISERROR(N'Sale identity below Cloud floor — run Cloud_Reseed_TransactionIdRanges.sql first.', 16, 1);
    RETURN;
END

PRINT 'Identity OK SaleHead=' + CAST(@h AS nvarchar(30)) + N' SaleDetail=' + CAST(@d AS nvarchar(30));
GO

-- Install / refresh Cloud outbox triggers (sets CaptureCloud=1 inside proc)
EXEC dbo.SyncInstall_CloudCapture @TableName = N'SaleHead';
EXEC dbo.SyncInstall_CloudCapture @TableName = N'SaleDetail';
GO

-- Reinforce config (table name matches DataSync_28 / Check-C2LStatus)
UPDATE dbo.SyncConfig
SET IsEnabled = 1,
    CaptureCloud = 1,
    CaptureLocal = 0,
    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | Sale C2L on ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHERE TableName IN (N'SaleHead', N'SaleDetail');

IF @@ROWCOUNT < 2
    PRINT 'WARN: SyncConfig rows missing for Sale — SyncInstall_CloudCapture should have updated/created; check SyncConfig table name.';
ELSE
    PRINT 'SyncConfig SaleHead/SaleDetail: CaptureCloud=1, CaptureLocal=0, IsEnabled=1';
GO

PRINT '=== Verify ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig
WHERE TableName IN (N'SaleHead', N'SaleDetail')
ORDER BY TableName;

SELECT name AS TriggerName, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_SaleHead', N'tr_SyncOutbox_SaleDetail')
ORDER BY name;

PRINT '';
PRINT 'LOCAL (separate SSMS — once): ensure apply enabled, capture stays OFF:';
PRINT '  UPDATE dbo.SyncConfig SET IsEnabled=1, CaptureCloud=0 WHERE TableName IN (N''SaleHead'',N''SaleDetail'');';
PRINT 'Smoke: docs/sql/SyncTest_C2L_Sale.sql then one Cloud Sale → Agent → Local ID >= 2e9';
GO
