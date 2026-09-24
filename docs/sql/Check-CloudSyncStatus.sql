/*
  Cloud DB verify — run on CLOUD (SQL1002.site4now.net / db_abbe78_warehouse)
  sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P YOUR_PASSWORD -C -I -i Check-CloudSyncStatus.sql
*/

SET NOCOUNT ON;

PRINT '=== Cloud: row counts (key tables) ===';
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + N'
IF OBJECT_ID(N''dbo.' + name + N''', N''U'') IS NOT NULL
    INSERT INTO #cnt(TableName, RowCnt) SELECT N''' + name + N''', COUNT(*) FROM dbo.' + QUOTENAME(name) + N';'
FROM (VALUES
    (N'Setting'), (N'Customer'), (N'Stock'), (N'Branch'),
    (N'SaleHead'), (N'SaleDetail'),
    (N'PurchaseHead'), (N'PurchaseDetail'),
    (N'RawIssueHead'), (N'RawIssueDetail'),
    (N'FinishGoodsHead'), (N'FinishGoodsDetail')
) v(name);

CREATE TABLE #cnt (TableName sysname, RowCnt bigint);
EXEC sp_executesql @sql;
SELECT * FROM #cnt ORDER BY TableName;
DROP TABLE #cnt;

PRINT '=== Cloud: Setting Date ===';
IF OBJECT_ID(N'dbo.Setting', N'U') IS NOT NULL
    SELECT ID, Date, LogDay, Name, SyncModifiedAt, SyncOrigin FROM dbo.Setting WHERE ID = 1;

PRINT '=== Cloud: sync infrastructure ===';
SELECT COUNT(*) AS EnabledTables FROM dbo.SyncConfig WHERE IsEnabled = 1;
SELECT name FROM sys.procedures WHERE name IN (N'SyncApply_Generic', N'SyncApply_Customer') ORDER BY name;
GO
