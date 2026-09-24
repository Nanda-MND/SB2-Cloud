/*
  SB1 online performance tune — NO database stop, ERP can keep running.

  Safe for SQL Server Standard (no ONLINE rebuild required).
  Run on Server\SB1 during business hours (may be slightly slower while running).

  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -i DataSync_27_OnlinePerformanceTune.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== 1. Cap SQL memory (16 GB PC — leave ~6 GB for OS + ERP) ===';
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'max server memory (MB)', 10240;  -- 10 GB for SQL; use 8192 if ERP runs on SAME PC
RECONFIGURE;
PRINT 'max server memory set to 10240 MB. Change to 8192 if SQL+ERP same machine.';
GO

PRINT '=== 2. REORGANIZE high-fragmentation indexes (online, low lock) ===';
-- Reorganize is online-safe on Standard Edition (rebuild ONLINE needs Enterprise)

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.SaleHead') AND name = N'PK_SaleHead')
BEGIN
    PRINT 'Reorganizing PK_SaleHead...';
    ALTER INDEX PK_SaleHead ON dbo.SaleHead REORGANIZE;
END

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.SaleDetail') AND name = N'PK_SaleDetail')
BEGIN
    PRINT 'Reorganizing PK_SaleDetail...';
    ALTER INDEX PK_SaleDetail ON dbo.SaleDetail REORGANIZE;
END

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.TransferDetail') AND name = N'PK_TransferDetail')
BEGIN
    PRINT 'Reorganizing PK_TransferDetail...';
    ALTER INDEX PK_TransferDetail ON dbo.TransferDetail REORGANIZE;
END

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.IncomeExpenseDetail') AND name = N'PK_IncomeExpenseDetail')
BEGIN
    PRINT 'Reorganizing PK_IncomeExpenseDetail...';
    ALTER INDEX PK_IncomeExpenseDetail ON dbo.IncomeExpenseDetail REORGANIZE;
END
GO

PRINT '=== 3. Update statistics (online) ===';
UPDATE STATISTICS dbo.SaleHead WITH FULLSCAN;
UPDATE STATISTICS dbo.SaleDetail WITH FULLSCAN;
UPDATE STATISTICS dbo.SaleOrderHead WITH FULLSCAN;
UPDATE STATISTICS dbo.SaleOrderDetail WITH FULLSCAN;
UPDATE STATISTICS dbo.TransferDetail WITH FULLSCAN;
UPDATE STATISTICS dbo.IncomeExpenseDetail WITH FULLSCAN;
UPDATE STATISTICS dbo.StockDetail WITH FULLSCAN;
UPDATE STATISTICS dbo.Customer WITH FULLSCAN;
PRINT 'Statistics updated.';
GO

PRINT '=== 4. SyncOutbox — purge old Synced rows only (DB stays up) ===';
-- Agent can keep running; deleting Synced rows is safe
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
BEGIN
    DECLARE @d int;
    DELETE FROM dbo.SyncOutbox WHERE Direction = N'L2C' AND Status = N'Synced';
    SET @d = @@ROWCOUNT;
    PRINT 'SyncOutbox Synced rows removed: ' + CAST(@d AS nvarchar(20));
END
GO

PRINT '=== 5. Verify ===';
SELECT name, CAST(value_in_use AS int) AS max_mem_mb
FROM sys.configurations WHERE name = N'max server memory (MB)';

SELECT TOP 5 OBJECT_NAME(ips.object_id) AS T, i.name AS Idx,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,1)) AS FragPct
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, N'LIMITED') ips
JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.page_count > 1000 AND i.name LIKE N'PK_%'
ORDER BY ips.avg_fragmentation_in_percent DESC;

SELECT physical_memory_in_use_kb / 1024 AS SQL_MemMB FROM sys.dm_os_process_memory;
GO

/*
  NOTE — REORGANIZE vs REBUILD:
  - REORGANIZE: online, safe during ERP use, fixes moderate fragmentation (~30-70% improvement)
  - REBUILD: stronger fix but blocks table briefly on Standard Edition
  - If still slow after REORGANIZE, schedule REBUILD one table at a time during lunch break (2-5 min each)

  16 GB RAM guide:
  - SQL dedicated server (clients remote): max server memory = 10240 (10 GB)
  - SQL + ERP on same PC:               max server memory = 8192  (8 GB)
*/
GO
