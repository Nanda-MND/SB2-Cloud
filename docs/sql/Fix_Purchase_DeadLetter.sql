/*
  Fix PurchaseHead / PurchaseDetail DeadLetter on CLOUD after restore.

  Errors fixed:
    1) Cannot insert explicit value for identity column ... IDENTITY_INSERT is OFF
       -> Redeploy SyncApply_Generic + Purchase wrappers + db_owner for cloud login
    2) Cannot convert a char value to money
       -> Safer money parsing in SyncApply_Generic (empty string -> NULL)

  Run on CLOUD:
    sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P xxx -C -I -i Fix_Purchase_DeadLetter.sql

  Then on LOCAL retry:
    sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -Q "UPDATE dbo.SyncOutbox SET Status=N'Pending', AttemptCount=0, LastError=NULL WHERE Direction=N'L2C' AND Status=N'DeadLetter' AND TableName IN (N'PurchaseHead',N'PurchaseDetail');"
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Grant db_owner so IDENTITY_INSERT works for hosted login
IF USER_ID(N'db_abbe78_warehouse_admin') IS NOT NULL
   AND IS_ROLEMEMBER(N'db_owner', N'db_abbe78_warehouse_admin') = 0
    ALTER ROLE db_owner ADD MEMBER [db_abbe78_warehouse_admin];
GO

-- Must run DataSync_10_SyncApply_Generic.sql BEFORE this file (or ensure Generic exists with IDENTITY_INSERT block)
IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    RAISERROR(N'Run DataSync_10_SyncApply_Generic.sql on Cloud first.', 16, 1);
END
GO

IF OBJECT_ID(N'dbo.SyncApply_PurchaseHead', N'P') IS NOT NULL DROP PROCEDURE dbo.SyncApply_PurchaseHead;
GO
CREATE PROCEDURE dbo.SyncApply_PurchaseHead
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source, @TableName = N'PurchaseHead',
        @PayloadJson = @PayloadJson, @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt, @Operation = NULL,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

IF OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NOT NULL DROP PROCEDURE dbo.SyncApply_PurchaseDetail;
GO
CREATE PROCEDURE dbo.SyncApply_PurchaseDetail
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL, @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source, @TableName = N'PurchaseDetail',
        @PayloadJson = @PayloadJson, @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt, @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

PRINT 'Purchase SyncApply wrappers installed on Cloud.';
GO
