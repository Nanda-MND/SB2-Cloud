/*
  CLOUD smoke — after DataSync_32_EnableC2L_Sale.sql

  A) Confirm capture
  B) Optional: touch an existing high-ID sale OR insert test note
  C) Check outbox

  Do not run on Local.
*/

SET NOCOUNT ON;

PRINT '=== Sale C2L config ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig
WHERE TableName IN (N'SaleHead', N'SaleDetail');

PRINT '=== Triggers ===';
SELECT name, OBJECT_NAME(parent_id) AS ParentTable, is_disabled
FROM sys.triggers
WHERE name LIKE N'tr_SyncOutbox_Sale%';

PRINT '=== Identity ===';
SELECT
    IDENT_CURRENT(N'dbo.SaleHead') AS SaleHeadIdent,
    IDENT_CURRENT(N'dbo.SaleDetail') AS SaleDetailIdent;

PRINT '=== Recent C2L Sale outbox ===';
SELECT TOP 20 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt, LEFT(ISNULL(LastError, N''), 80) AS LastError
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'SaleHead', N'SaleDetail')
ORDER BY OutboxID DESC;

PRINT '';
PRINT 'To queue a test C2L row (CLOUD only), update an existing SaleHead remark, e.g.:';
PRINT '  UPDATE dbo.SaleHead SET Remark = ISNULL(Remark,N'''') + N'' [C2L-test]'' WHERE ID = <existingCloudOrSyncedId>;';
PRINT 'Or create a new Sale in Cloud UI — ID should be >= 2000000000.';
GO
