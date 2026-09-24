/*
  ============================================================================
  LOCAL ONLY — restore L2C for ALL entry (transaction) tables
  ============================================================================
  Pair (Cloud edit → Local):
    docs/sql/Fix_AllTxn_Cloud_C2L_Capture.sql
  Guide:
    docs/sql/README_Txn_Bidirectional_Sync.md

  Symptom:
    Local Save on Sale / Purchase / Transfer / IE / Manufacture / Opening
    does not update Cloud.

  Cause:
    C2L scripts left CaptureLocal=0 on Local for those tables.

  This script (LOCAL SB1):
    - CaptureLocal = 1, CaptureCloud = 0, IsEnabled = 1
    - Reinstalls tr_SyncOutbox_* via dbo.SyncInstall_Table when present

  Do NOT run on Cloud.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== DB: ' + DB_NAME() + N' — Fix ALL entry L2C (LOCAL) ===';
PRINT N'Started: ' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126);
GO

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
BEGIN
    RAISERROR(N'dbo.SyncConfig missing — wrong database?', 16, 1);
    RETURN;
END
GO

DECLARE @Entry TABLE (TableName sysname PRIMARY KEY, Priority int NOT NULL);

INSERT INTO @Entry (TableName, Priority) VALUES
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
-- Manufacture (actual names from DataSync_15)
(N'RawIssueHead', 40), (N'RawIssueDetail', 45),
(N'FinishGoodsHead', 40), (N'FinishGoodsDetail', 45),
(N'ReturnStockHead', 40), (N'ReturnStockDetail', 45),
(N'GetStockHead', 40), (N'GetStockDetail', 45),
-- Finance
(N'IncomeExpenseHead', 40), (N'IncomeExpenseDetail', 45),
(N'AccountOpeningHead', 42), (N'AccountOpeningDetail', 45),
(N'JournalHead', 40), (N'JournalDetail', 45),
-- Party opening / transfer (if tables exist)
(N'CustomerOpeningHead', 42), (N'CustomerOpeningDetail', 45),
(N'SupplierOpeningHead', 42), (N'SupplierOpeningDetail', 45),
(N'ManufacturerOpeningHead', 42), (N'ManufacturerOpeningDetail', 45),
(N'CustSupTransfer', 40);

PRINT N'=== BEFORE ===';
SELECT
    e.TableName,
    HasTable = CASE WHEN OBJECT_ID(N'dbo.' + e.TableName, N'U') IS NULL THEN 0 ELSE 1 END,
    c.IsEnabled,
    c.CaptureLocal,
    c.CaptureCloud,
    HasTrigger = CASE WHEN OBJECT_ID(N'dbo.tr_SyncOutbox_' + e.TableName, N'TR') IS NULL THEN 0 ELSE 1 END
FROM @Entry e
LEFT JOIN dbo.SyncConfig c ON c.TableName = e.TableName
ORDER BY e.Priority, e.TableName;

DECLARE @t sysname, @p int;
DECLARE @ok int = 0, @skip int = 0, @err int = 0;
DECLARE @hasInstall bit = CASE WHEN OBJECT_ID(N'dbo.SyncInstall_Table', N'P') IS NOT NULL THEN 1 ELSE 0 END;

IF @hasInstall = 0
    PRINT N'WARN: dbo.SyncInstall_Table missing — config will update; recreate triggers via DataSync_11 if needed.';

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, Priority FROM @Entry ORDER BY Priority, TableName;

OPEN cur;
FETCH NEXT FROM cur INTO @t, @p;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.' + @t, N'U') IS NULL
    BEGIN
        PRINT N'SKIP (no table): ' + @t;
        SET @skip += 1;
    END
    ELSE
    BEGIN
        BEGIN TRY
            IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = @t)
            BEGIN
                UPDATE dbo.SyncConfig
                SET IsEnabled = 1,
                    CaptureLocal = 1,
                    CaptureCloud = 0,
                    Notes = LEFT(CONCAT(ISNULL(Notes, N''), N' | Entry L2C ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
                WHERE TableName = @t;
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
                    @t, 1, 1, 0,
                    N'ID', 100, @p, N'Entry L2C restored'
                );
            END

            IF @hasInstall = 1
                EXEC dbo.SyncInstall_Table
                    @TableName = @t,
                    @InstallCapture = 1,
                    @Priority = @p;

            -- Ensure flags stay L2C after SyncInstall_Table MERGE
            UPDATE dbo.SyncConfig
            SET IsEnabled = 1,
                CaptureLocal = 1,
                CaptureCloud = 0
            WHERE TableName = @t;

            SET @ok += 1;
            PRINT N'OK L2C: ' + @t;
        END TRY
        BEGIN CATCH
            SET @err += 1;
            PRINT N'WARN ' + @t + N': ' + ERROR_MESSAGE();
        END CATCH
    END

    FETCH NEXT FROM cur INTO @t, @p;
END
CLOSE cur;
DEALLOCATE cur;

PRINT N'=== DONE ok=' + CAST(@ok AS nvarchar(10))
    + N' skip=' + CAST(@skip AS nvarchar(10))
    + N' err=' + CAST(@err AS nvarchar(10)) + N' ===';

PRINT N'=== AFTER (expect CaptureLocal=1, CaptureCloud=0) ===';
SELECT
    e.TableName,
    c.IsEnabled,
    c.CaptureLocal,
    c.CaptureCloud,
    HasTrigger = CASE WHEN OBJECT_ID(N'dbo.tr_SyncOutbox_' + e.TableName, N'TR') IS NULL THEN 0 ELSE 1 END
FROM @Entry e
INNER JOIN dbo.SyncConfig c ON c.TableName = e.TableName
WHERE OBJECT_ID(N'dbo.' + e.TableName, N'U') IS NOT NULL
ORDER BY e.Priority, e.TableName;

PRINT N'=== Still wrong (should be empty) ===';
SELECT e.TableName, c.IsEnabled, c.CaptureLocal, c.CaptureCloud
FROM @Entry e
INNER JOIN dbo.SyncConfig c ON c.TableName = e.TableName
WHERE OBJECT_ID(N'dbo.' + e.TableName, N'U') IS NOT NULL
  AND (
        ISNULL(c.IsEnabled, 0) <> 1
     OR ISNULL(c.CaptureLocal, 0) <> 1
     OR ISNULL(c.CaptureCloud, 0) <> 0
  )
ORDER BY e.TableName;

PRINT N'Next: edit entry on Local → SyncOutbox L2C Pending → Agent → Cloud.';
GO
