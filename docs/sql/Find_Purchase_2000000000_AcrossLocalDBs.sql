/*
  LOCAL instance — find which database actually received C2L Purchase 2000000000.
  Run on Server\SB1 (or whatever instance SyncAgent uses), any DB context.
*/

SET NOCOUNT ON;

DECLARE @sql nvarchar(max) = N'';

SELECT @sql += N'
IF EXISTS (SELECT 1 FROM ' + QUOTENAME(name) + N'.sys.tables WHERE name = N''PurchaseHead'')
BEGIN
    IF EXISTS (SELECT 1 FROM ' + QUOTENAME(name) + N'.dbo.PurchaseHead WHERE ID = 2000000000)
        SELECT DB = N''' + name + N''', ObjectType = N''PurchaseHead'', ID
        FROM ' + QUOTENAME(name) + N'.dbo.PurchaseHead WHERE ID = 2000000000;
END
'
FROM sys.databases
WHERE state_desc = N'ONLINE'
  AND name NOT IN (N'master', N'tempdb', N'model', N'msdb');

EXEC sp_executesql @sql;

PRINT 'If a DB name prints above, SyncAgent Initial Catalog is THAT DB — not the SB1 you queried.';
PRINT 'If no rows: Agent Apply reported success but inserted nowhere (check SyncApply_Generic on the Agent Local DB).';
GO
