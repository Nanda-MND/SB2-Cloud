/*
  Cloud hosted SQL: IDENTITY_INSERT requires db_owner (site4now).

  Run on CLOUD (SSMS connected to db_abbe78_warehouse):
    Fix_Cloud_IdentityInsert.sql

  Sync Agent uses login: db_abbe78_warehouse_admin (CloudConnection.ini)
*/

SET NOCOUNT ON;

DECLARE @cu sysname = USER_NAME();
DECLARE @grantSql nvarchar(max);

PRINT '=== Connected as ===';
SELECT SUSER_SNAME() AS LoginName, USER_NAME() AS DbUser;

-- Grant db_owner to Sync Agent login (map login -> existing DB user if name differs)
DECLARE @agentDbUser sysname;

SELECT @agentDbUser = dp.name
FROM sys.database_principals dp
INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE sp.name = N'db_abbe78_warehouse_admin';

IF @agentDbUser IS NOT NULL
BEGIN
    PRINT 'Agent login mapped to DB user: ' + @agentDbUser;
    IF IS_ROLEMEMBER(N'db_owner', @agentDbUser) = 0
    BEGIN
        DECLARE @agentGrant nvarchar(max) = N'ALTER ROLE db_owner ADD MEMBER ' + QUOTENAME(@agentDbUser);
        EXEC sp_executesql @agentGrant;
        PRINT 'Granted db_owner to ' + @agentDbUser;
    END
    ELSE
        PRINT @agentDbUser + N' already db_owner.';

    -- IDENTITY_INSERT also needs ALTER on target tables (db_owner covers this; explicit for hosted SQL)
    DECLARE @tbl sysname;
    DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM (VALUES
            (N'SaleHead'), (N'SaleDetail'), (N'PurchaseHead'), (N'PurchaseDetail'), (N'VoucherEditing')
        ) v(name)
        WHERE OBJECT_ID(N'dbo.' + name, N'U') IS NOT NULL;
    OPEN tbl_cur;
    FETCH NEXT FROM tbl_cur INTO @tbl;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @grantSql = N'GRANT SELECT, INSERT, UPDATE, DELETE, ALTER ON dbo.' + QUOTENAME(@tbl) + N' TO ' + QUOTENAME(@agentDbUser);
            EXEC sp_executesql @grantSql;
        END TRY
        BEGIN CATCH
            PRINT 'WARN: GRANT on ' + @tbl + N': ' + ERROR_MESSAGE();
        END CATCH
        FETCH NEXT FROM tbl_cur INTO @tbl;
    END
    CLOSE tbl_cur;
    DEALLOCATE tbl_cur;
END
ELSE IF SUSER_ID(N'db_abbe78_warehouse_admin') IS NOT NULL
BEGIN
    BEGIN TRY
        CREATE USER [db_abbe78_warehouse_admin] FOR LOGIN [db_abbe78_warehouse_admin];
        SET @agentDbUser = N'db_abbe78_warehouse_admin';
        PRINT 'Created database user db_abbe78_warehouse_admin.';
        ALTER ROLE db_owner ADD MEMBER [db_abbe78_warehouse_admin];
    END TRY
    BEGIN CATCH
        PRINT 'WARN: could not create user for agent login: ' + ERROR_MESSAGE();
        SELECT @agentDbUser = dp.name
        FROM sys.database_principals dp
        INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
        WHERE sp.name = N'db_abbe78_warehouse_admin';
        IF @agentDbUser IS NOT NULL
            PRINT 'Using existing mapped user: ' + @agentDbUser;
    END CATCH
END
ELSE
    PRINT 'WARN: server login db_abbe78_warehouse_admin not found — check CloudConnection.ini user.';

-- Current SSMS user (if not agent login)
IF IS_ROLEMEMBER(N'db_owner') = 0
BEGIN
    BEGIN TRY
        SET @grantSql = N'ALTER ROLE db_owner ADD MEMBER ' + QUOTENAME(@cu);
        EXEC sp_executesql @grantSql;
        PRINT 'Granted db_owner to current user: ' + @cu;
    END TRY
    BEGIN CATCH
        PRINT 'WARN: could not grant db_owner to current user: ' + ERROR_MESSAGE();
    END CATCH
END

IF IS_ROLEMEMBER(N'db_owner') = 1
    PRINT 'Current user is db_owner: OK';
ELSE
    PRINT 'WARN: current user is NOT db_owner — deploy SyncApply as dbo/db_owner.';

PRINT '=== Test IDENTITY_INSERT (current user) ===';
BEGIN TRY
    IF OBJECT_ID(N'dbo.SaleHead', N'U') IS NOT NULL
       AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.SaleHead'))
    BEGIN
        SET IDENTITY_INSERT dbo.SaleHead ON;
        SET IDENTITY_INSERT dbo.SaleHead OFF;
        PRINT 'IDENTITY_INSERT test on SaleHead: OK';
    END
END TRY
BEGIN CATCH
    PRINT 'IDENTITY_INSERT test FAILED: ' + ERROR_MESSAGE();
END CATCH

PRINT '=== Test as Sync Agent user (if mapped) ===';
IF @agentDbUser IS NOT NULL
BEGIN
    BEGIN TRY
        SET @grantSql = N'
EXECUTE AS USER = ' + QUOTENAME(@agentDbUser) + N';
SET IDENTITY_INSERT dbo.SaleHead ON;
SET IDENTITY_INSERT dbo.SaleHead OFF;
REVERT;';
        EXEC sp_executesql @grantSql;
        PRINT 'IDENTITY_INSERT as ' + @agentDbUser + N': OK';
    END TRY
    BEGIN CATCH
        PRINT 'IDENTITY_INSERT as agent user FAILED: ' + ERROR_MESSAGE();
    END CATCH
END
GO

PRINT 'Next: run DataSync_10_SyncApply_Generic.sql on Cloud';
GO
