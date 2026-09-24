/*
  SB1 database size diagnostic — run on LOCAL (Server\SB1 / SB1)
  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -i DataSync_24_SizeDiagnostic.sql
*/

SET NOCOUNT ON;

PRINT '=== 1. Database file sizes ===';
SELECT
    name AS FileName,
    type_desc,
    CAST(size * 8.0 / 1024 AS decimal(10, 2)) AS SizeMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS decimal(10, 2)) AS UsedMB
FROM sys.database_files
ORDER BY type_desc, name;

PRINT '=== 2. Top 25 tables by reserved space ===';
SELECT TOP 25
    t.name AS TableName,
    SUM(p.rows) AS RowCnt,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS decimal(10, 2)) AS TotalMB,
    CAST(SUM(a.used_pages) * 8.0 / 1024 AS decimal(10, 2)) AS UsedMB,
    CAST(SUM(a.data_pages) * 8.0 / 1024 AS decimal(10, 2)) AS DataMB
FROM sys.tables t
INNER JOIN sys.indexes i ON i.object_id = t.object_id
INNER JOIN sys.partitions p ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.allocation_units a ON a.container_id = p.partition_id
WHERE t.is_ms_shipped = 0 AND i.index_id <= 1
GROUP BY t.name
ORDER BY TotalMB DESC;

PRINT '=== 3. Sync-related objects ===';
SELECT
    t.name AS TableName,
    SUM(p.rows) AS RowCnt,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS decimal(10, 2)) AS TotalMB
FROM sys.tables t
INNER JOIN sys.indexes i ON i.object_id = t.object_id
INNER JOIN sys.partitions p ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.allocation_units a ON a.container_id = p.partition_id
WHERE t.name LIKE N'Sync%' OR t.name IN (N'StockStatus', N'GeneralLedgerDetail')
GROUP BY t.name
ORDER BY TotalMB DESC;

PRINT '=== 4. SyncOutbox by Status ===';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
BEGIN
    SELECT Status, COUNT(*) AS Cnt
    FROM dbo.SyncOutbox WHERE Direction = N'L2C'
    GROUP BY Status ORDER BY Status;

    SELECT
        COUNT(*) AS TotalRows,
        AVG(DATALENGTH(PayloadJson)) AS AvgPayloadBytes,
        MAX(DATALENGTH(PayloadJson)) AS MaxPayloadBytes,
        SUM(DATALENGTH(PayloadJson)) / 1024.0 / 1024.0 AS PayloadJsonTotalMB
    FROM dbo.SyncOutbox
    WHERE Direction = N'L2C';
END

PRINT '=== 5. Sync columns overhead (tables with SyncModifiedAt) ===';
SELECT COUNT(*) AS TablesWithSyncColumns
FROM sys.columns
WHERE name = N'SyncModifiedAt';

PRINT '=== 6. Outbox triggers count ===';
SELECT COUNT(*) AS OutboxTriggerCount
FROM sys.triggers
WHERE name LIKE N'tr_SyncOutbox_%';

PRINT '=== 7. Log reuse / recovery ===';
SELECT
    recovery_model_desc,
    log_reuse_wait_desc,
    user_access_desc
FROM sys.databases
WHERE name = DB_NAME();
GO
