/*
  Diagnose C2L Sales voucher not reaching Local.

  Run on CLOUD first, then LOCAL.
*/

SET NOCOUNT ON;
PRINT '=== DB: ' + DB_NAME() + ' ===';

-- 1) SaleHead/SaleDetail sync config
PRINT '=== SyncConfig Sale ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig
WHERE TableName IN (N'SaleHead', N'SaleDetail');

-- 2) Trigger installed?
PRINT '=== Sale triggers ===';
SELECT name, OBJECT_NAME(parent_id) AS TableName, create_date, modify_date
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_SaleHead', N'tr_SyncOutbox_SaleDetail');

-- 3) Trigger checks CaptureLocal or CaptureCloud?
PRINT '=== Trigger body (first 500 chars) ===';
SELECT name, LEFT(OBJECT_DEFINITION(object_id), 500) AS DefStart
FROM sys.triggers
WHERE name IN (N'tr_SyncOutbox_SaleHead', N'tr_SyncOutbox_SaleDetail');

-- 4) C2L outbox for Sales
PRINT '=== C2L outbox SaleHead/SaleDetail ===';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
    SELECT TOP 20 OutboxID, TableName, Status, Operation, CreatedAt, SyncedAt,
           LEFT(LastError, 120) AS LastError, LEFT(PrimaryKeyJson, 80) AS PK
    FROM dbo.SyncOutbox
    WHERE Direction = N'C2L'
      AND TableName IN (N'SaleHead', N'SaleDetail')
    ORDER BY OutboxID DESC;

-- 5) Latest SaleHead on this DB
PRINT '=== Latest SaleHead (top 3) ===';
IF OBJECT_ID(N'dbo.SaleHead', N'U') IS NOT NULL
    SELECT TOP 3 ID, [Date], Deleted, SyncModifiedAt, SyncOrigin
    FROM dbo.SaleHead ORDER BY ID DESC;
GO
