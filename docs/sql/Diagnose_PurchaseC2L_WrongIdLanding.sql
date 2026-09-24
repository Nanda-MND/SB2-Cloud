/*
  LOCAL — Why Purchase C2L Synced but ID 2000000000 missing
  while Sale/Transfer cloud-zone IDs exist.
*/

SET NOCOUNT ON;

PRINT '=== Cloud-zone counts ===';
SELECT 'Sale' T, COUNT(*) Cnt FROM dbo.SaleHead WHERE ID >= 2000000000
UNION ALL SELECT 'Transfer', COUNT(*) FROM dbo.TransferHead WHERE ID >= 2000000000
UNION ALL SELECT 'Purchase', COUNT(*) FROM dbo.PurchaseHead WHERE ID >= 2000000000;

PRINT '=== Purchase with SyncOrigin=2 (Cloud) — maybe landed under NEW local ID ===';
IF COL_LENGTH(N'dbo.PurchaseHead', N'SyncOrigin') IS NOT NULL
    SELECT TOP 30 ID, Date, AutoID, UserID, Remark, SyncOrigin, SyncModifiedAt
    FROM dbo.PurchaseHead
    WHERE SyncOrigin = 2
    ORDER BY SyncModifiedAt DESC;
ELSE
    PRINT 'No SyncOrigin column';

PRINT '=== Recent PurchaseHead (any) today ===';
SELECT TOP 20 ID, Date, AutoID, UserID, Remark, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
ORDER BY ID DESC;

PRINT '=== SyncApply procs ===';
SELECT name, modify_date
FROM sys.procedures
WHERE name IN (N'SyncApply_Generic', N'SyncApply_PurchaseHead', N'SyncApply_PurchaseDetail',
               N'SyncApply_SaleHead', N'SyncApply_TransferHead')
ORDER BY name;

PRINT '=== IDENTITY_INSERT test rights (sa should be fine) ===';
SELECT HAS_PERMS_BY_NAME(N'dbo.PurchaseHead', N'OBJECT', N'ALTER') AS CanAlterPurchaseHead;

PRINT '=== PurchaseHead identity ===';
SELECT IDENT_CURRENT(N'dbo.PurchaseHead') AS IdentCurrent,
       (SELECT MAX(ID) FROM dbo.PurchaseHead WHERE ID < 2000000000) AS MaxLocalZone,
       (SELECT MAX(ID) FROM dbo.PurchaseHead WHERE ID >= 2000000000) AS MaxCloudZone;
GO
