/*
  Option C — C2L master data ONLY on CLOUD.

  Home/Cloud: edit Customer, Stock, Setting, Users, etc. → C2L → Local
  Sales/Purchase vouchers: enter at OFFICE Local only → L2C → Cloud

  Run on CLOUD only (db_abbe78_warehouse):
    sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U ... -C -I -i DataSync_31_DisableC2L_Transactions.sql

  Does NOT disable L2C (office → cloud). Only turns off Cloud capture (CaptureCloud=0)
  and drops C2L outbox triggers for transaction tables.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @ExcludeAlways TABLE (TableName sysname PRIMARY KEY);
INSERT @ExcludeAlways (TableName) VALUES
    (N'GeneralLedgerDetail'),
    (N'stockInOutBalance'),
    (N'StockStartup'),
    (N'StockStatus'),
    (N'Tmp_StockOpening'),
    (N'UserStatus');

DECLARE @TxnExplicit TABLE (TableName sysname PRIMARY KEY);
INSERT @TxnExplicit (TableName) VALUES
    (N'SaleHead'), (N'SaleDetail'),
    (N'PurchaseHead'), (N'PurchaseDetail'),
    (N'SaleOrderHead'), (N'SaleOrderDetail'),
    (N'SaleReturnHead'), (N'SaleReturnDetail'),
    (N'PurchaseOrderHead'), (N'PurchaseOrderDetail'),
    (N'PurchaseReturnHead'), (N'PurchaseReturnDetail'),
    (N'TransferHead'), (N'TransferDetail'),
    (N'AdjustmentHead'), (N'AdjustmentDetail'),
    (N'StockReceiveHead'), (N'StockReceiveDetail'),
    (N'ReturnReceiveHead'), (N'ReturnReceiveDetail'),
    (N'StockOpeningHead'), (N'StockOpeningDetail'),
    (N'RawIssueHead'), (N'RawIssueDetail'),
    (N'FinishGoodsHead'), (N'FinishGoodsDetail'),
    (N'ReturnStockHead'), (N'ReturnStockDetail'),
    (N'GetStockHead'), (N'GetStockDetail'),
    (N'IncomeExpenseHead'), (N'IncomeExpenseDetail'),
    (N'AccountOpeningHead'), (N'AccountOpeningDetail'),
    (N'JournalHead'), (N'JournalDetail');

DECLARE @toDisable TABLE (TableName sysname PRIMARY KEY);

INSERT @toDisable (TableName)
SELECT c.TableName
FROM dbo.SyncConfig c
WHERE c.CaptureCloud = 1
  AND (
      c.Priority >= 40
      OR EXISTS (SELECT 1 FROM @TxnExplicit t WHERE t.TableName = c.TableName)
  )
  AND NOT EXISTS (SELECT 1 FROM @ExcludeAlways e WHERE e.TableName = c.TableName);

PRINT '=== C2L disable (transactions) ===';
SELECT TableName FROM @toDisable ORDER BY TableName;

DECLARE @t sysname, @n int = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @toDisable ORDER BY TableName;
OPEN cur;
FETCH NEXT FROM cur INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.tr_SyncOutbox_' + @t, N'TR') IS NOT NULL
    BEGIN
        EXEC(N'DROP TRIGGER dbo.tr_SyncOutbox_' + @t);
        PRINT N'Dropped tr_SyncOutbox_' + @t;
    END

    UPDATE dbo.SyncConfig
    SET CaptureCloud = 0,
        Notes = N'C2L off (Option C master-only) ' + CONVERT(nvarchar(30), sysutcdatetime(), 126)
    WHERE TableName = @t;
    SET @n += @@ROWCOUNT;

    FETCH NEXT FROM cur INTO @t;
END
CLOSE cur;
DEALLOCATE cur;

PRINT 'SyncConfig CaptureCloud=0: ' + CAST(@n AS nvarchar(10));

DELETE o
FROM dbo.SyncOutbox o
INNER JOIN @toDisable d ON d.TableName = o.TableName
WHERE o.Direction = N'C2L'
  AND o.Status IN (N'Pending', N'Syncing');
PRINT 'C2L pending queue removed: ' + CAST(@@ROWCOUNT AS nvarchar(10));

PRINT '=== C2L still ON (master / reference) ===';
SELECT TableName, Priority, CaptureCloud, CaptureLocal
FROM dbo.SyncConfig
WHERE CaptureCloud = 1
ORDER BY Priority, TableName;

PRINT '=== C2L OFF (transactions sample) ===';
SELECT TOP 15 TableName, Priority, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (SELECT TableName FROM @TxnExplicit)
ORDER BY TableName;

PRINT 'DataSync_31 completed.';
GO
