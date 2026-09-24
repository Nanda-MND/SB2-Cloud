/*
  ============================================================================
  LOCAL + CLOUD — add @Operation to SyncApply wrappers that Agent already sends
  ============================================================================
  Symptom (Sync Status / Dead letter):
    Procedure or function SyncApply_SaleHead has too many arguments specified.

  Cause: SyncAgent always passes @Operation for *Head / *Detail, but older
  SyncApply_SaleHead / SyncApply_Customer lack that parameter.

  Safe: DROP/CREATE only listed wrappers; leaves SyncApply_Generic alone.
  Run on BOTH Local SB1 and Cloud warehouse.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'Fix SyncApply wrappers — add @Operation';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME;
PRINT N'============================================================';

IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    RAISERROR(N'STOP: SyncApply_Generic missing. Run DataSync_10_SyncApply_Generic.sql first.', 16, 1);
    RETURN;
END
GO

/* ---------- SaleHead ---------- */
IF OBJECT_ID(N'dbo.SyncApply_SaleHead', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_SaleHead;
GO
CREATE PROCEDURE dbo.SyncApply_SaleHead
    @Source varchar(10),
    @PayloadJson nvarchar(max),
    @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500),
    @OutboxID bigint = NULL,
    @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT,
    @Applied bit OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'SaleHead',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO
PRINT N'SyncApply_SaleHead OK (+@Operation).';
GO

/* ---------- SaleDetail (ensure @Operation) ---------- */
IF OBJECT_ID(N'dbo.SyncApply_SaleDetail', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_SaleDetail;
GO
CREATE PROCEDURE dbo.SyncApply_SaleDetail
    @Source varchar(10),
    @PayloadJson nvarchar(max),
    @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500),
    @OutboxID bigint = NULL,
    @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT,
    @Applied bit OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'SaleDetail',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO
PRINT N'SyncApply_SaleDetail OK (+@Operation).';
GO

/* ---------- PurchaseHead / PurchaseDetail ---------- */
IF OBJECT_ID(N'dbo.SyncApply_PurchaseHead', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_PurchaseHead;
GO
CREATE PROCEDURE dbo.SyncApply_PurchaseHead
    @Source varchar(10),
    @PayloadJson nvarchar(max),
    @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500),
    @OutboxID bigint = NULL,
    @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT,
    @Applied bit OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'PurchaseHead',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

IF OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_PurchaseDetail;
GO
CREATE PROCEDURE dbo.SyncApply_PurchaseDetail
    @Source varchar(10),
    @PayloadJson nvarchar(max),
    @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500),
    @OutboxID bigint = NULL,
    @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT,
    @Applied bit OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'PurchaseDetail',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO
PRINT N'SyncApply_PurchaseHead/Detail OK (+@Operation).';
GO

/* ---------- Customer ---------- */
IF OBJECT_ID(N'dbo.SyncApply_Customer', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_Customer;
GO
CREATE PROCEDURE dbo.SyncApply_Customer
    @Source varchar(10),
    @PayloadJson nvarchar(max),
    @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500),
    @OutboxID bigint = NULL,
    @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT,
    @Applied bit OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'Customer',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO
PRINT N'SyncApply_Customer OK (+@Operation).';
GO

/* ---------- Requeue DeadLetter caused by too-many-arguments ---------- */
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
BEGIN
    UPDATE dbo.SyncOutbox
    SET Status = N'Pending',
        AttemptCount = 0,
        LastError = NULL,
        SyncedAt = NULL,
        SyncModifiedAt = SYSUTCDATETIME()
    WHERE Status IN (N'DeadLetter', N'Conflict', N'Syncing')
      AND (
            LastError LIKE N'%too many arguments%'
         OR LastError LIKE N'%SyncApply_SaleHead%'
         OR LastError LIKE N'%SyncApply_Customer%'
         OR LastError LIKE N'%SyncApply_Purchase%'
          );
    PRINT N'Requeued arg-mismatch DeadLetter/Conflict: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END
GO

PRINT N'============================================================';
PRINT N'DONE. Run this on BOTH Local and Cloud.';
PRINT N'Then: Cloud Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql';
PRINT N'Keep SyncAgent running. Dead letter count should fall.';
PRINT N'============================================================';
GO
