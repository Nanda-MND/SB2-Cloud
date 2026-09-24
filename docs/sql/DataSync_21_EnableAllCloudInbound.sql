/*
  Enable ALL tables on CLOUD for inbound apply (L2C) — NO triggers.

  Fixes repeated errors:
    SyncApply_Generic: table X not enabled in SyncConfig

  Run once on Cloud after partial pilot install left IsEnabled=0 or missing rows.

  sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P xxx -C -I -i DataSync_21_EnableAllCloudInbound.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== 1. Enable all existing SyncConfig rows ===';
UPDATE dbo.SyncConfig SET IsEnabled = 1 WHERE IsEnabled = 0;
PRINT 'Rows updated: ' + CAST(@@ROWCOUNT AS nvarchar(10));

PRINT '=== 2. Insert missing SyncConfig for eligible dbo tables ===';
INSERT INTO dbo.SyncConfig (
    TableName, IsEnabled, CaptureLocal, CaptureCloud,
    PrimaryKeyColumns, BatchSize, Priority, Notes
)
SELECT
    t.name,
    1,
    0,
    0,
    pk.PkCol,
    100,
    CASE
        WHEN t.name LIKE N'%Detail' THEN 45
        WHEN t.name LIKE N'%Head' THEN 40
        ELSE 30
    END,
    N'Inserted by DataSync_21 ' + CONVERT(nvarchar(30), sysutcdatetime(), 126)
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'dbo'
INNER JOIN (
    SELECT i.object_id
    FROM sys.indexes i
    WHERE i.is_primary_key = 1
    GROUP BY i.object_id
    HAVING COUNT(*) = 1
) spk ON spk.object_id = t.object_id
CROSS APPLY (
    SELECT TOP 1 c.name AS PkCol
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = t.object_id AND i.is_primary_key = 1
    ORDER BY ic.key_ordinal
) pk
WHERE t.name NOT LIKE N'Sync%'
  AND t.name NOT IN (N'sysdiagrams', N'dtproperties', N'__EFMigrationsHistory', N'__MigrationHistory')
  AND NOT EXISTS (SELECT 1 FROM dbo.SyncConfig c WHERE c.TableName = t.name);
PRINT 'Rows inserted: ' + CAST(@@ROWCOUNT AS nvarchar(10));

PRINT '=== 3. Summary ===';
SELECT
    SUM(CASE WHEN IsEnabled = 1 THEN 1 ELSE 0 END) AS Enabled,
    SUM(CASE WHEN IsEnabled = 0 THEN 1 ELSE 0 END) AS Disabled,
    COUNT(*) AS Total
FROM dbo.SyncConfig;

PRINT '=== 4. Still disabled (should be 0) ===';
SELECT c.TableName, c.IsEnabled
FROM dbo.SyncConfig c
WHERE c.IsEnabled = 0
ORDER BY c.TableName;
GO
