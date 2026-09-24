/*
  Enable tables on CLOUD for inbound apply (L2C) — NO triggers.

  Use when SyncApply_Generic fails with:
    "table X not enabled in SyncConfig"

  Do NOT run SyncInstall_Table on Cloud for this fix (Msg 111 CREATE TRIGGER batch error).
  Cloud only needs SyncConfig.IsEnabled = 1 for SyncApply_Generic.

  sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P xxx -C -I -i DataSync_19_EnableCloudTables.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @EnableTables TABLE (TableName sysname PRIMARY KEY);
INSERT @EnableTables (TableName) VALUES
    (N'VoucherEditing'),
    (N'SalesID'),
    (N'UserRights'),
    (N'Setting'),
    (N'CustSupTransfer'),
    (N'Stock'),
    (N'Users');
-- Or run DataSync_21_EnableAllCloudInbound.sql for ALL tables at once

PRINT '=== Enable Cloud SyncConfig (inbound apply only) ===';

-- 1) Existing rows
UPDATE c SET
    IsEnabled = 1,
    Notes = COALESCE(c.Notes, N'') + N' | Enabled DataSync_19 ' + CONVERT(nvarchar(30), sysutcdatetime(), 126)
FROM dbo.SyncConfig c
INNER JOIN @EnableTables e ON e.TableName = c.TableName;
PRINT 'Updated existing SyncConfig: ' + CAST(@@ROWCOUNT AS nvarchar(10));

-- 2) Missing rows — insert from PK metadata (no triggers)
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
    30,
    N'Inserted by DataSync_19 ' + CONVERT(nvarchar(30), sysutcdatetime(), 126)
FROM sys.tables t
INNER JOIN @EnableTables e ON e.TableName = t.name
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'dbo'
CROSS APPLY (
    SELECT TOP 1 c.name AS PkCol
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = t.object_id AND i.is_primary_key = 1
    ORDER BY ic.key_ordinal
) pk
WHERE NOT EXISTS (SELECT 1 FROM dbo.SyncConfig c WHERE c.TableName = t.name);
PRINT 'Inserted new SyncConfig: ' + CAST(@@ROWCOUNT AS nvarchar(10));

PRINT '=== Verify ===';
SELECT c.TableName, c.IsEnabled, c.CaptureLocal, c.CaptureCloud, c.PrimaryKeyColumns
FROM dbo.SyncConfig c
INNER JOIN @EnableTables e ON e.TableName = c.TableName
ORDER BY c.TableName;
GO
