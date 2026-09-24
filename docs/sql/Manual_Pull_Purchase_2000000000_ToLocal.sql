/*
  LOCAL SB1 — manually pull Purchase 2000000000 from Cloud when C2L marks Synced but Local empty.

  Option 1 (linked / same network): edit @Cloud and run.
  Option 2: on CLOUD run the SELECT...FOR JSON, paste into Option 2 below.

  Also fix SyncAgent DBConnection.ini → Data Source=Server\SB1; Initial Catalog=SB1
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ========== Option 1: four-part / linked server name ========== */
/*
DECLARE @Cloud sysname = N'YOUR_LINKED_CLOUD';  -- or use OPENROWSET

SET IDENTITY_INSERT dbo.PurchaseHead ON;
INSERT INTO dbo.PurchaseHead (
  ID, Date, AutoID, DocumentID, StockReceived, LocationID, SupplierID, CurrencyID, PaymentID,
  AccountID, ExRate, Remark, Balance, Amount, Discount, NetAmount, Tax, TotalAmount, Paid, TotalBalance,
  Deleted, EditUserID, EditDate
)
SELECT
  ID, Date, AutoID, DocumentID, StockReceived, LocationID, SupplierID, CurrencyID, PaymentID,
  AccountID, ExRate, Remark, Balance, Amount, Discount, NetAmount, Tax, TotalAmount, Paid, TotalBalance,
  Deleted, EditUserID, EditDate
FROM CloudDB.dbo.PurchaseHead  -- change to real cloud four-part name
WHERE ID = 2000000000
  AND NOT EXISTS (SELECT 1 FROM dbo.PurchaseHead h WHERE h.ID = 2000000000);
SET IDENTITY_INSERT dbo.PurchaseHead OFF;

SET IDENTITY_INSERT dbo.PurchaseDetail ON;
INSERT INTO dbo.PurchaseDetail (
  ID, RefID, Sr, CodeID, BrandID, Qty, UnitID, Price, Weight, Amount, TotalWeight, Remark, Qty1, Qty2
)
SELECT
  ID, RefID, Sr, CodeID, BrandID, Qty, UnitID, Price, Weight, Amount, TotalWeight, Remark, Qty1, Qty2
FROM CloudDB.dbo.PurchaseDetail
WHERE RefID = 2000000000
  AND NOT EXISTS (SELECT 1 FROM dbo.PurchaseDetail d WHERE d.ID = ID);
SET IDENTITY_INSERT dbo.PurchaseDetail OFF;
*/

PRINT '=== Prefer: force SyncApply on LOCAL using Cloud payload ===';
PRINT 'On CLOUD run:';
PRINT '  SELECT PayloadJson FROM dbo.SyncOutbox WHERE OutboxID = <PurchaseHead outbox id>;';
PRINT '  SELECT PayloadJson FROM dbo.SyncOutbox WHERE OutboxID = <PurchaseDetail outbox id>;';
PRINT 'Then paste into @HeadJson / @DetailJson and uncomment block below.';
GO

/* ========== Option 2: SyncApply_Generic on LOCAL (paste payloads) ========== */
/*
DECLARE @HeadJson nvarchar(max) = N'...paste...';
DECLARE @DetailJson nvarchar(max) = N'...paste...';
DECLARE @Conflict bit, @Applied bit;

EXEC dbo.SyncApply_Generic
  @Source=N'Cloud', @TableName=N'PurchaseHead', @PayloadJson=@HeadJson,
  @PrimaryKeyJson=N'{"ID":2000000000}', @RemoteModifiedAt=SYSUTCDATETIME(),
  @Operation=N'I', @OutboxID=NULL,
  @ConflictLogged=@Conflict OUTPUT, @Applied=@Applied OUTPUT;
SELECT HeadApplied=@Applied, HeadConflict=@Conflict;

EXEC dbo.SyncApply_Generic
  @Source=N'Cloud', @TableName=N'PurchaseDetail', @PayloadJson=@DetailJson,
  @PrimaryKeyJson=N'{"ID":2000000000}', @RemoteModifiedAt=SYSUTCDATETIME(),
  @Operation=N'I', @OutboxID=NULL,
  @ConflictLogged=@Conflict OUTPUT, @Applied=@Applied OUTPUT;
SELECT DetailApplied=@Applied, DetailConflict=@Conflict;

SELECT ID FROM dbo.PurchaseHead WHERE ID=2000000000;
SELECT ID, RefID FROM dbo.PurchaseDetail WHERE RefID=2000000000;
*/
GO

PRINT 'CRITICAL: SyncAgent DBConnection.ini Data Source must be this instance + Initial Catalog=SB1';
PRINT '  SB.SyncAgent.exe /decrypt DBConnection.ini';
GO
