/*
  Report: which dbo tables are NOT yet enabled for sync.
  Run on LOCAL (Server\SB1 / SB1).
*/

SET NOCOUNT ON;

PRINT '=== Summary ===';
SELECT
    (SELECT COUNT(*) FROM sys.tables t
     INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
     WHERE s.name = N'dbo' AND t.name NOT LIKE N'Sync%'
       AND t.name NOT IN (N'sysdiagrams', N'dtproperties')) AS TotalUserTables,
    (SELECT COUNT(*) FROM dbo.SyncConfig WHERE IsEnabled = 1) AS EnabledInSyncConfig,
    (SELECT COUNT(*) FROM sys.triggers WHERE name LIKE N'tr_SyncOutbox_%') AS OutboxTriggers;
GO

PRINT '=== Tables MISSING from SyncConfig (eligible: single PK) ===';
SELECT t.name AS TableName
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'dbo'
  AND t.name NOT LIKE N'Sync%'
  AND t.name NOT IN (N'sysdiagrams', N'dtproperties', N'__EFMigrationsHistory', N'__MigrationHistory')
  AND EXISTS (
      SELECT 1 FROM sys.indexes i
      WHERE i.object_id = t.object_id AND i.is_primary_key = 1
      GROUP BY i.object_id HAVING COUNT(*) = 1
  )
  AND NOT EXISTS (SELECT 1 FROM dbo.SyncConfig c WHERE c.TableName = t.name)
ORDER BY t.name;
GO

PRINT '=== Enabled but NO outbox trigger on LOCAL ===';
SELECT c.TableName
FROM dbo.SyncConfig c
WHERE c.IsEnabled = 1 AND c.CaptureLocal = 1
  AND NOT EXISTS (
      SELECT 1 FROM sys.triggers tr
      WHERE tr.name = N'tr_SyncOutbox_' + c.TableName
  )
ORDER BY c.TableName;
GO

PRINT '=== ERP transaction tables — sync status ===';
;WITH erp AS (
    SELECT TableName FROM (VALUES
        (N'RawIssueHead'), (N'RawIssueDetail'),
        (N'FinishGoodsHead'), (N'FinishGoodsDetail'),
        (N'ReturnStockHead'), (N'ReturnStockDetail'),
        (N'GetStockHead'), (N'GetStockDetail'),
        (N'TransferHead'), (N'TransferDetail'),
        (N'AdjustmentHead'), (N'AdjustmentDetail'),
        (N'StockReceiveHead'), (N'StockReceiveDetail'),
        (N'SaleOrderHead'), (N'SaleOrderDetail'),
        (N'SaleReturnHead'), (N'SaleReturnDetail'),
        (N'PurchaseOrderHead'), (N'PurchaseOrderDetail'),
        (N'PurchaseReturnHead'), (N'PurchaseReturnDetail'),
        (N'IncomeExpenseHead'), (N'IncomeExpenseDetail'),
        (N'StockOpeningHead'), (N'StockOpeningDetail'),
        (N'AccountOpeningHead'), (N'AccountOpeningDetail'),
        (N'ReturnReceiveHead'), (N'ReturnReceiveDetail'),
        (N'Stock'), (N'StockDetail'), (N'Supplier'), (N'Manufacturer')
    ) v(TableName)
)
SELECT
    e.TableName,
    CASE WHEN OBJECT_ID(N'dbo.' + e.TableName, N'U') IS NULL THEN N'MissingTable'
         WHEN c.TableName IS NULL THEN N'NotInSyncConfig'
         WHEN c.IsEnabled = 0 THEN N'Disabled'
         WHEN c.CaptureLocal = 0 THEN N'NoCapture'
         ELSE N'OK' END AS SyncStatus,
    c.Priority,
    ISNULL(o.Synced, 0) AS Synced,
    ISNULL(o.Pending, 0) AS Pending
FROM erp e
LEFT JOIN dbo.SyncConfig c ON c.TableName = e.TableName
LEFT JOIN (
    SELECT TableName,
           SUM(CASE WHEN Status = N'Synced' THEN 1 ELSE 0 END) AS Synced,
           SUM(CASE WHEN Status = N'Pending' THEN 1 ELSE 0 END) AS Pending
    FROM dbo.SyncOutbox WHERE Direction = N'L2C'
    GROUP BY TableName
) o ON o.TableName = e.TableName
ORDER BY e.TableName;
GO
