/*
  Enable sync for remaining ERP tables (Manufacturing, Transfer, etc.)
  Run AFTER DataSync_11_AllTables_Install.sql on LOCAL (InstallCapture=1).

  Idempotent: calls SyncInstall_Table for each known ERP table if it exists.
  Also safe if DataSync_11 already ran (re-installs triggers + SyncConfig).
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.SyncInstall_Table', 'P') IS NULL
BEGIN
    RAISERROR(N'Run DataSync_11_AllTables_Install.sql first (creates SyncInstall_Table).', 16, 1);
    RETURN;
END
GO

DECLARE @InstallCapture bit = 1;
IF @InstallCapture NOT IN (0, 1) SET @InstallCapture = 1;
-- sqlcmd Cloud: use -v InstallCapture=0

DECLARE @tables TABLE (
    TableName sysname NOT NULL,
    Priority  tinyint NULL
);

INSERT @tables (TableName, Priority) VALUES
-- Manufacturing
(N'RawIssueHead', 40), (N'RawIssueDetail', 45),
(N'FinishGoodsHead', 40), (N'FinishGoodsDetail', 45),
(N'ReturnStockHead', 40), (N'ReturnStockDetail', 45),
(N'GetStockHead', 40), (N'GetStockDetail', 45),
-- Inventory / transfer
(N'TransferHead', 40), (N'TransferDetail', 45),
(N'AdjustmentHead', 40), (N'AdjustmentDetail', 45),
(N'StockReceiveHead', 40), (N'StockReceiveDetail', 45),
(N'ReturnReceiveHead', 40), (N'ReturnReceiveDetail', 45),
(N'StockOpeningHead', 42), (N'StockOpeningDetail', 45),
-- Sales / purchase variants
(N'SaleOrderHead', 40), (N'SaleOrderDetail', 45),
(N'SaleReturnHead', 40), (N'SaleReturnDetail', 45),
(N'PurchaseOrderHead', 40), (N'PurchaseOrderDetail', 45),
(N'PurchaseReturnHead', 40), (N'PurchaseReturnDetail', 45),
-- Finance
(N'IncomeExpenseHead', 40), (N'IncomeExpenseDetail', 45),
(N'AccountOpeningHead', 42), (N'AccountOpeningDetail', 45),
(N'JournalHead', 40), (N'JournalDetail', 45),
-- Master (if not already from DataSync_11)
(N'Stock', 10), (N'StockDetail', 15),
(N'Supplier', 10), (N'Manufacturer', 10),
(N'Brand', 10), (N'Unit', 10), (N'Users', 5);

DECLARE @t sysname, @p tinyint, @n int = 0, @skip int = 0;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, Priority FROM @tables ORDER BY Priority, TableName;

OPEN cur;
FETCH NEXT FROM cur INTO @t, @p;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.' + @t, N'U') IS NULL
    BEGIN
        PRINT N'SKIP (not in DB): ' + @t;
        SET @skip += 1;
    END
    ELSE
    BEGIN
        BEGIN TRY
            EXEC dbo.SyncInstall_Table @TableName = @t, @InstallCapture = @InstallCapture, @Priority = @p;
            SET @n += 1;
            PRINT N'OK: ' + @t;
        END TRY
        BEGIN CATCH
            PRINT N'WARN ' + @t + N': ' + ERROR_MESSAGE();
        END CATCH
    END
    FETCH NEXT FROM cur INTO @t, @p;
END
CLOSE cur;
DEALLOCATE cur;

PRINT N'DataSync_15 completed. Installed/updated: ' + CAST(@n AS nvarchar(10))
    + N', skipped (missing table): ' + CAST(@skip AS nvarchar(10));
PRINT N'Next: run DataSync_14_MasterPriority.sql then DataSync_13_InitialSeed.sql on LOCAL.';
GO