/*
  Cloud L2C diagnose — run on CLOUD (db_abbe78_warehouse) in SSMS.
  Shows why SaleHead / VoucherEditing push fails.
*/

SET NOCOUNT ON;

PRINT '=== 1. Sync apply procedures ===';
SELECT name AS ProcName
FROM sys.procedures
WHERE name LIKE N'SyncApply%'
ORDER BY name;

IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
    PRINT 'FAIL: dbo.SyncApply_Generic MISSING — run DataSync_10_SyncApply_Generic.sql';
ELSE
BEGIN
    DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'));
    SELECT
        CASE WHEN @def LIKE N'%WITH EXECUTE AS OWNER%' OR @def LIKE N'%EXECUTE AS OWNER%' THEN 1 ELSE 0 END AS HasExecuteAsOwner,
        CASE WHEN @def LIKE N'%SET IDENTITY_INSERT%ON;%INSERT%' THEN 1
             WHEN @def LIKE N'%SET IDENTITY_INSERT%' AND @def LIKE N'%INSERT INTO%' THEN 1
             ELSE 0 END AS HasCombinedIdentityBatch,
        USER_NAME(OBJECTPROPERTY(OBJECT_ID(N'dbo.SyncApply_Generic'), N'OwnerId')) AS ProcOwner;
END

PRINT '=== 2. Agent login mapping ===';
SELECT
    sp.name AS LoginName,
    dp.name AS DbUser,
    IS_ROLEMEMBER(N'db_owner', dp.name) AS IsDbOwner
FROM sys.server_principals sp
LEFT JOIN sys.database_principals dp ON dp.sid = sp.sid
WHERE sp.name = N'db_abbe78_warehouse_admin';

PRINT '=== 3. Sale wrappers (delegate to Generic) ===';
SELECT name FROM sys.procedures
WHERE name IN (N'SyncApply_SaleHead', N'SyncApply_SaleDetail', N'SyncApply_PurchaseHead', N'SyncApply_PurchaseDetail')
ORDER BY name;

PRINT '=== 4. SyncConfig enabled (push targets) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'SaleHead', N'SaleDetail', N'VoucherEditing', N'Setting', N'PurchaseHead', N'PurchaseDetail')
ORDER BY TableName;

PRINT '=== 5. IDENTITY_INSERT test (current SSMS user) ===';
BEGIN TRY
    SET IDENTITY_INSERT dbo.SaleHead ON;
    SET IDENTITY_INSERT dbo.SaleHead OFF;
    PRINT 'Current user IDENTITY_INSERT: OK';
END TRY
BEGIN CATCH
    PRINT 'Current user IDENTITY_INSERT FAILED: ' + ERROR_MESSAGE();
END CATCH

DECLARE @agentDbUser sysname;
SELECT @agentDbUser = dp.name
FROM sys.database_principals dp
INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE sp.name = N'db_abbe78_warehouse_admin';

IF @agentDbUser IS NOT NULL
BEGIN
    PRINT '=== 6. IDENTITY_INSERT test (agent DB user: ' + @agentDbUser + N') ===';
    BEGIN TRY
        DECLARE @t nvarchar(max) = N'
EXECUTE AS USER = ' + QUOTENAME(@agentDbUser) + N';
SET IDENTITY_INSERT dbo.SaleHead ON;
SET IDENTITY_INSERT dbo.SaleHead OFF;
REVERT;';
        EXEC sp_executesql @t;
        PRINT 'Agent user IDENTITY_INSERT: OK';
    END TRY
    BEGIN CATCH
        PRINT 'Agent user IDENTITY_INSERT FAILED: ' + ERROR_MESSAGE();
        PRINT 'Fix: run Fix_Cloud_IdentityInsert.sql';
    END CATCH
END
ELSE
    PRINT 'WARN: agent login not mapped to a DB user on this database.';
GO
