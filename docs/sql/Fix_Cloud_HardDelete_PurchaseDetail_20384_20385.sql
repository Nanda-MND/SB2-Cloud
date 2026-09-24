/*
  ============================================================================
  CLOUD ONLY — remove ghost PurchaseDetail 20384/20385 + verify hard-delete apply
  ============================================================================
  Local already sent Op=D (even Synced) but rows still on Cloud with Remark='test'.
  Root: SyncApply_Generic missing hardDeleteDetail and/or wrapper missing @Operation.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== CLOUD fix ghost detail deletes 20384/20385 ===';
PRINT N'DB=' + DB_NAME();

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'STOP: Local DB. Run on CLOUD warehouse.', 16, 1);
    RETURN;
END
GO

PRINT N'--- 0) Before ---';
SELECT ID, RefID, Sr, Remark, IsDeleted
FROM dbo.PurchaseDetail
WHERE ID IN (20384, 20385) OR (RefID = 2000000006 AND Remark = N'test');
GO

PRINT N'--- 1) SyncApply markers ---';
SELECT
  CASE WHEN OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL THEN N'MISSING'
       WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) LIKE N'%hardDeleteDetail%'
            THEN N'OK_hardDeleteDetail'
       ELSE N'BAD_run_DataSync_10' END AS ApplyVer,
  CASE WHEN OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NULL THEN N'MISSING'
       WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_PurchaseDetail')) LIKE N'%@Operation%'
            THEN N'OK_@Operation'
       ELSE N'BAD_missing_@Operation' END AS DetailWrapper;
GO

/* If markers BAD: stop and tell user to run DataSync_10 + Fix_DetailDelete first.
   Still remove ghosts so UI is correct now. */

PRINT N'--- 2) Hard-delete ghost rows ---';
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;

DELETE FROM dbo.PurchaseDetail
WHERE ID IN (20384, 20385)
   OR (RefID = 2000000006 AND Remark = N'test');
PRINT N'Deleted rows: ' + CAST(@@ROWCOUNT AS nvarchar(20));

BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
GO

PRINT N'--- 3) After (expect only 2000000012 / 2000000013) ---';
SELECT ID, RefID, Sr, Remark
FROM dbo.PurchaseDetail
WHERE RefID = 2000000006
ORDER BY ID;
GO

/* Ensure apply path for NEXT deletes */
IF OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) NOT LIKE N'%hardDeleteDetail%'
    PRINT N'WARNING: still run DataSync_10_SyncApply_Generic.sql on CLOUD';
ELSE
    PRINT N'SyncApply_Generic hardDeleteDetail OK';

IF OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NULL
   OR OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_PurchaseDetail')) NOT LIKE N'%@Operation%'
BEGIN
    PRINT N'Installing SyncApply_PurchaseDetail +@Operation...';
    IF OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NOT NULL
        DROP PROCEDURE dbo.SyncApply_PurchaseDetail;
END
GO

IF OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NULL
   AND OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NOT NULL
BEGIN
    EXEC(N'
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
        @TableName = N''PurchaseDetail'',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END');
    PRINT N'SyncApply_PurchaseDetail created (+@Operation).';
END
ELSE IF OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NOT NULL
   AND OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_PurchaseDetail')) LIKE N'%@Operation%'
    PRINT N'SyncApply_PurchaseDetail already has @Operation.';
GO

PRINT N'=== DONE. Local Pending Op=D can Sync; future deletes need hardDeleteDetail. ===';
GO
