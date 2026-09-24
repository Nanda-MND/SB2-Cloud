/*
  Fix Customer IDENTITY_INSERT DeadLetter errors on Cloud.
  Run A on CLOUD, then B on LOCAL. SyncAgent can keep running.
*/

-- ========== A) CLOUD ONLY ==========
IF IS_ROLEMEMBER('db_owner', 'db_abbe78_warehouse_admin') = 0
    ALTER ROLE db_owner ADD MEMBER [db_abbe78_warehouse_admin];
GO

IF OBJECT_ID('dbo.SyncApply_Generic', 'P') IS NULL
BEGIN
    RAISERROR('Run DataSync_10_SyncApply_Generic.sql on Cloud first.', 16, 1);
END
GO

IF OBJECT_ID('dbo.SyncApply_Customer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_Customer;
GO

CREATE PROCEDURE dbo.SyncApply_Customer
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source, @TableName = N'Customer',
        @PayloadJson = @PayloadJson, @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt, @Operation = NULL,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

PRINT 'Cloud Customer fix applied.';
GO
