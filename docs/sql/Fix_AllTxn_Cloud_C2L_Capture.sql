/*
  ============================================================================
  CLOUD ONLY — enable C2L for ALL transaction (entry) tables
  ============================================================================
  Goal: Cloud edit → Local (C2L) for every transaction Head/Detail.

  Sets: IsEnabled=1, CaptureCloud=1, CaptureLocal=0
  Installs: dbo.tr_SyncOutbox_* via SyncInstall_CloudCapture

  Prerequisite on Cloud:
    docs/sql/DataSync_28_EnableC2L_Capture.sql  (creates SyncInstall_CloudCapture)

  Pair with LOCAL:
    docs/sql/Fix_AllEntry_Local_L2C_Capture.sql  (Local edit → Cloud)

  Do NOT run on Local.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== DB: ' + DB_NAME() + N' — Enable ALL txn C2L (CLOUD) ===';
PRINT N'Started: ' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126);
GO

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
BEGIN
    RAISERROR(N'dbo.SyncConfig missing — wrong database?', 16, 1);
    RETURN;
END
GO

IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
BEGIN
    RAISERROR(N'Missing dbo.SyncInstall_CloudCapture. Run DataSync_28_EnableC2L_Capture.sql on Cloud first.', 16, 1);
    RETURN;
END
GO

DECLARE @Txn TABLE (TableName sysname PRIMARY KEY, Priority int NOT NULL);

INSERT INTO @Txn (TableName, Priority) VALUES
-- Core
(N'SaleHead', 40), (N'SaleDetail', 45),
(N'PurchaseHead', 40), (N'PurchaseDetail', 45),
(N'SaleOrderHead', 40), (N'SaleOrderDetail', 45),
(N'SaleReturnHead', 40), (N'SaleReturnDetail', 45),
(N'PurchaseOrderHead', 40), (N'PurchaseOrderDetail', 45),
(N'PurchaseReturnHead', 40), (N'PurchaseReturnDetail', 45),
-- Stock / transfer
(N'TransferHead', 40), (N'TransferDetail', 45),
(N'AdjustmentHead', 40), (N'AdjustmentDetail', 45),
(N'StockReceiveHead', 40), (N'StockReceiveDetail', 45),
(N'ReturnReceiveHead', 40), (N'ReturnReceiveDetail', 45),
(N'StockOpeningHead', 42), (N'StockOpeningDetail', 45),
-- Manufacture (skip automatically if table missing)
(N'RawIssueHead', 40), (N'RawIssueDetail', 45),
(N'FinishGoodsHead', 40), (N'FinishGoodsDetail', 45),
(N'ReturnStockHead', 40), (N'ReturnStockDetail', 45),
(N'GetStockHead', 40), (N'GetStockDetail', 45),
-- Finance
(N'IncomeExpenseHead', 40), (N'IncomeExpenseDetail', 45),
(N'AccountOpeningHead', 42), (N'AccountOpeningDetail', 45),
(N'JournalHead', 40), (N'JournalDetail', 45),
-- Party opening / transfer
(N'CustomerOpeningHead', 42), (N'CustomerOpeningDetail', 45),
(N'SupplierOpeningHead', 42), (N'SupplierOpeningDetail', 45),
(N'ManufacturerOpeningHead', 42), (N'ManufacturerOpeningDetail', 45),
(N'CustSupTransfer', 40);

PRINT N'=== BEFORE ===';
SELECT
    t.TableName,
    HasTable = CASE WHEN OBJECT_ID(N'dbo.' + t.TableName, N'U') IS NULL THEN 0 ELSE 1 END,
    c.IsEnabled,
    c.CaptureLocal,
    c.CaptureCloud,
    HasTrigger = CASE WHEN OBJECT_ID(N'dbo.tr_SyncOutbox_' + t.TableName, N'TR') IS NULL THEN 0 ELSE 1 END
FROM @Txn t
LEFT JOIN dbo.SyncConfig c ON c.TableName = t.TableName
ORDER BY t.Priority, t.TableName;

DECLARE @name sysname, @prio int;
DECLARE @ok int = 0, @skip int = 0, @err int = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, Priority FROM @Txn ORDER BY Priority, TableName;

OPEN cur;
FETCH NEXT FROM cur INTO @name, @prio;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.' + @name, N'U') IS NULL
    BEGIN
        PRINT N'SKIP (no table): ' + @name;
        SET @skip += 1;
    END
    ELSE
    BEGIN
        BEGIN TRY
            IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = @name)
            BEGIN
                UPDATE dbo.SyncConfig
                SET IsEnabled = 1,
                    CaptureCloud = 1,
                    CaptureLocal = 0,
                    Priority = ISNULL(Priority, @prio),
                    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | Txn C2L ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
                WHERE TableName = @name;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.SyncConfig
                (
                    TableName, IsEnabled, CaptureLocal, CaptureCloud,
                    PrimaryKeyColumns, BatchSize, Priority, Notes
                )
                VALUES
                (
                    @name, 1, 0, 1,
                    N'ID', 100, @prio, N'Txn C2L enabled'
                );
            END

            EXEC dbo.SyncInstall_CloudCapture @TableName = @name;

            UPDATE dbo.SyncConfig
            SET IsEnabled = 1,
                CaptureCloud = 1,
                CaptureLocal = 0
            WHERE TableName = @name;

            SET @ok += 1;
            PRINT N'OK C2L: ' + @name;
        END TRY
        BEGIN CATCH
            SET @err += 1;
            PRINT N'WARN ' + @name + N': ' + ERROR_MESSAGE();
        END CATCH
    END

    FETCH NEXT FROM cur INTO @name, @prio;
END
CLOSE cur;
DEALLOCATE cur;

PRINT N'=== DONE ok=' + CAST(@ok AS nvarchar(10))
    + N' skip=' + CAST(@skip AS nvarchar(10))
    + N' err=' + CAST(@err AS nvarchar(10)) + N' ===';

PRINT N'=== AFTER (expect CaptureCloud=1, CaptureLocal=0) ===';
SELECT
    t.TableName,
    c.IsEnabled,
    c.CaptureLocal,
    c.CaptureCloud,
    HasTrigger = CASE WHEN OBJECT_ID(N'dbo.tr_SyncOutbox_' + t.TableName, N'TR') IS NULL THEN 0 ELSE 1 END
FROM @Txn t
INNER JOIN dbo.SyncConfig c ON c.TableName = t.TableName
WHERE OBJECT_ID(N'dbo.' + t.TableName, N'U') IS NOT NULL
ORDER BY t.Priority, t.TableName;

PRINT N'=== Still wrong (should be empty) ===';
SELECT t.TableName, c.IsEnabled, c.CaptureLocal, c.CaptureCloud
FROM @Txn t
INNER JOIN dbo.SyncConfig c ON c.TableName = t.TableName
WHERE OBJECT_ID(N'dbo.' + t.TableName, N'U') IS NOT NULL
  AND (
        ISNULL(c.IsEnabled, 0) <> 1
     OR ISNULL(c.CaptureCloud, 0) <> 1
     OR ISNULL(c.CaptureLocal, 0) <> 0
  )
ORDER BY t.TableName;

PRINT N'Next: edit txn on Cloud → SyncOutbox Direction=C2L Pending → Agent → Local.';
PRINT N'Pair: run Fix_AllEntry_Local_L2C_Capture.sql on LOCAL for Local→Cloud.';
GO
