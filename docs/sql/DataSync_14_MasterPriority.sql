/*
  Set sync priorities so master/reference data reaches Cloud before transactions.
  Run on BOTH Local and Cloud after DataSync_11_AllTables_Install.sql.

  Lower Priority number = synced first.
*/

SET NOCOUNT ON;
GO

UPDATE dbo.SyncConfig SET Priority = 5
WHERE TableName IN (
    N'User', N'Users', N'Company', N'Branch', N'Currency', N'Unit', N'UOM'
);

UPDATE dbo.SyncConfig SET Priority = 10
WHERE TableName IN (
    N'Customer', N'Supplier', N'Location', N'Stock', N'StockGroup',
    N'Brand', N'Category', N'Code', N'CodeList', N'Ledger', N'Account',
    N'Employee', N'Driver', N'Warehouse', N'Bank', N'BankAccount'
);

UPDATE dbo.SyncConfig SET Priority = 15
WHERE TableName LIKE N'%Type'
   OR TableName LIKE N'%Group'
   OR TableName IN (N'StockStatus', N'PriceList', N'Rate', N'Tax', N'Discount');

UPDATE dbo.SyncConfig SET Priority = 40
WHERE TableName LIKE N'%Head' AND Priority > 40;

UPDATE dbo.SyncConfig SET Priority = 45
WHERE TableName LIKE N'%Detail' AND Priority > 45;

UPDATE dbo.SyncConfig SET Priority = 42
WHERE TableName LIKE N'%Opening%' AND Priority > 42;

PRINT '=== Sync priority summary (enabled tables) ===';
SELECT TableName, Priority, IsEnabled, CaptureLocal
FROM dbo.SyncConfig
WHERE IsEnabled = 1
ORDER BY Priority, TableName;
GO

PRINT 'DataSync_14_MasterPriority.sql completed.';
GO
