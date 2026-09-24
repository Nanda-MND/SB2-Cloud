/*
  ============================================================================
  BOTH Local SB1 + Cloud warehouse
  Fix: detail DELETE does not remove line on other side
  ============================================================================
  Prerequisites on THIS DB first:
    docs/sql/DataSync_10_SyncApply_Generic.sql   (must contain hardDeleteDetail)

  Then run THIS file on Local and Cloud.
  On Local also re-run (safe):
    docs/sql/DataSync_06_Purchase.sql
    → restores tr_SyncOutbox_PurchaseDetail with physical DELETE → Op=D
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'Fix Detail-delete sync — ' + DB_NAME() + N' @ ' + @@SERVERNAME;
PRINT N'============================================================';

IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
   OR OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) NOT LIKE N'%hardDeleteDetail%'
BEGIN
    RAISERROR(N'STOP: Run DataSync_10_SyncApply_Generic.sql on THIS DB first (need hardDeleteDetail).', 16, 1);
    RETURN;
END
PRINT N'SyncApply_Generic OK (hardDeleteDetail).';
GO

/* ---------- SyncApply_PurchaseDetail (+@Operation) ---------- */
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
PRINT N'SyncApply_PurchaseDetail OK (+@Operation).';
GO

/* ---------- SyncApply_SaleDetail (+@Operation) ---------- */
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

/* ---------- TransferDetail (+@Operation) ---------- */
IF OBJECT_ID(N'dbo.SyncApply_TransferDetail', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_TransferDetail;
GO
CREATE PROCEDURE dbo.SyncApply_TransferDetail
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
        @TableName = N'TransferDetail',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO
PRINT N'SyncApply_TransferDetail OK (+@Operation).';
GO

/* ---------- Remove IsDeleted=1 ghosts (UI still shows these) ---------- */
IF COL_LENGTH(N'dbo.PurchaseDetail', N'IsDeleted') IS NOT NULL
BEGIN
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY
        DELETE FROM dbo.PurchaseDetail WHERE ISNULL(IsDeleted, 0) = 1;
        PRINT N'PurchaseDetail ghosts removed: ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END TRY
    BEGIN CATCH
        PRINT N'PurchaseDetail ghost SKIP: ' + ERROR_MESSAGE();
    END CATCH
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
END

IF COL_LENGTH(N'dbo.TransferDetail', N'IsDeleted') IS NOT NULL
BEGIN
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY
        DELETE FROM dbo.TransferDetail WHERE ISNULL(IsDeleted, 0) = 1;
        PRINT N'TransferDetail ghosts removed: ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END TRY
    BEGIN CATCH
        PRINT N'TransferDetail ghost SKIP: ' + ERROR_MESSAGE();
    END CATCH
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
END
GO

/* ---------- Requeue recent Detail Op=D on this side ---------- */
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
BEGIN
    DECLARE @isLocal bit = CASE
        WHEN DB_NAME() IN (N'SB1', N'SB') THEN 1
        WHEN DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%' OR DB_NAME() LIKE N'%abb%' THEN 0
        ELSE 1 END;

    IF @isLocal = 1
    BEGIN
        UPDATE dbo.SyncOutbox
        SET Status = N'Pending',
            AttemptCount = 0,
            LastError = NULL,
            SyncedAt = NULL,
            SyncModifiedAt = SYSUTCDATETIME()
        WHERE Direction = N'L2C'
          AND TableName IN (N'PurchaseDetail', N'TransferDetail', N'SaleDetail')
          AND Operation = N'D'
          AND Status IN (N'Synced', N'Conflict', N'DeadLetter', N'Syncing')
          AND CreatedAt >= DATEADD(day, -7, SYSUTCDATETIME());
        PRINT N'LOCAL L2C *Detail Op=D requeued: ' + CAST(@@ROWCOUNT AS nvarchar(20));
        PRINT N'NEXT LOCAL: Fix_Transfer_Local_L2C_Capture.sql if Transfer DELETE capture BAD.';
    END
    ELSE
    BEGIN
        UPDATE dbo.SyncOutbox
        SET Status = N'Pending',
            AttemptCount = 0,
            LastError = NULL,
            SyncedAt = NULL,
            SyncModifiedAt = SYSUTCDATETIME()
        WHERE Direction = N'C2L'
          AND TableName LIKE N'%Detail'
          AND Operation = N'D'
          AND Status IN (N'Synced', N'Conflict', N'DeadLetter', N'Syncing')
          AND CreatedAt >= DATEADD(day, -7, SYSUTCDATETIME());
        PRINT N'CLOUD C2L *Detail Op=D requeued: ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END
END
GO

PRINT N'============================================================';
PRINT N'DONE on ' + DB_NAME();
PRINT N'Order reminder:';
PRINT N'  1) DataSync_10_SyncApply_Generic.sql   (both)';
PRINT N'  2) Fix_DetailDelete_Sync_BothSides.sql (both)  ← you are here';
PRINT N'  3) DataSync_06_Purchase.sql            (LOCAL — Purchase DELETE capture)';
PRINT N'  4) Fix_Transfer_Local_L2C_Capture.sql   (LOCAL — Transfer DELETE capture)';
PRINT N'  5) SyncAgent running → test detail delete';
PRINT N'============================================================';
GO
