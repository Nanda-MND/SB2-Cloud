/*
  Verify Cloud SyncApply_Generic is latest (IDENTITY_INSERT batch + EXECUTE AS OWNER).
  Run on CLOUD after DataSync_10 deploy.
*/

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    PRINT 'FAIL: dbo.SyncApply_Generic missing — run DataSync_10_SyncApply_Generic.sql';
    RETURN;
END

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'));

SELECT
    CASE WHEN @def LIKE N'%EXECUTE AS OWNER%' THEN 1 ELSE 0 END AS HasExecuteAsOwner,
    CASE WHEN @def LIKE N'%SET IDENTITY_INSERT%' THEN 1 ELSE 0 END AS HasIdentityInsert,
    CASE WHEN @def LIKE N'%@rowExists%' THEN 1 ELSE 0 END AS HasUpsertFix,
    USER_NAME(CASE WHEN OBJECTPROPERTY(OBJECT_ID(N'dbo.SyncApply_Generic'), N'OwnerId') IS NULL THEN 1 ELSE OBJECTPROPERTY(OBJECT_ID(N'dbo.SyncApply_Generic'), N'OwnerId') END) AS ProcOwner;

-- Agent login -> DB user
SELECT dp.name AS AgentDbUser, IS_ROLEMEMBER(N'db_owner', dp.name) AS IsDbOwner
FROM sys.database_principals dp
INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE sp.name = N'db_abbe78_warehouse_admin';

IF @def NOT LIKE N'%SET IDENTITY_INSERT%'
    PRINT 'FAIL: Old SyncApply_Generic — redeploy DataSync_10_SyncApply_Generic.sql';
ELSE
    PRINT 'OK: SyncApply_Generic looks current.';
GO
