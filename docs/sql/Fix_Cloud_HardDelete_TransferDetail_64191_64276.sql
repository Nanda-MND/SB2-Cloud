/*
  ============================================================================
  CLOUD ONLY — hard-delete ghost TransferDetail 64191/64276 (Remark=test)
  ============================================================================
  Local Op=D may have Synced without hard-delete (missing @Operation / hardDeleteDetail).
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== CLOUD hard-delete TransferDetail ghosts 64191/64276 ===';
PRINT N'DB=' + DB_NAME();

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'STOP: Local DB. Run on CLOUD warehouse.', 16, 1);
    RETURN;
END
GO

PRINT N'--- 0) Before ---';
SELECT ID, RefID, Sr, Remark, IsDeleted
FROM dbo.TransferDetail
WHERE ID IN (64191, 64276)
   OR (RefID = 2000000015 AND Remark = N'test');
GO

PRINT N'--- 1) SyncApply markers ---';
SELECT
  CASE WHEN OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL THEN N'MISSING'
       WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) LIKE N'%hardDeleteDetail%'
            THEN N'OK_hardDeleteDetail'
       ELSE N'BAD_run_DataSync_10' END AS ApplyVer,
  CASE WHEN OBJECT_ID(N'dbo.SyncApply_TransferDetail', N'P') IS NULL THEN N'MISSING'
       WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_TransferDetail')) LIKE N'%@Operation%'
            THEN N'OK_@Operation'
       ELSE N'BAD_missing_@Operation' END AS DetailWrapper;
GO

PRINT N'--- 2) Hard-delete ghosts ---';
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;

DELETE FROM dbo.TransferDetail
WHERE ID IN (64191, 64276)
   OR (RefID = 2000000015 AND Remark = N'test');
PRINT N'Deleted rows: ' + CAST(@@ROWCOUNT AS nvarchar(20));

BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
GO

PRINT N'--- 3) After (expect only 2000000087) ---';
SELECT ID, RefID, Sr, Remark
FROM dbo.TransferDetail
WHERE RefID = 2000000015
ORDER BY ID;
GO

/* Ensure TransferDetail wrapper accepts @Operation for future deletes */
IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NOT NULL
   AND (OBJECT_ID(N'dbo.SyncApply_TransferDetail', N'P') IS NULL
        OR OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_TransferDetail')) NOT LIKE N'%@Operation%')
BEGIN
    IF OBJECT_ID(N'dbo.SyncApply_TransferDetail', N'P') IS NOT NULL
        DROP PROCEDURE dbo.SyncApply_TransferDetail;

    EXEC(N'
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
        @TableName = N''TransferDetail'',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END');
    PRINT N'SyncApply_TransferDetail created (+@Operation).';
END
ELSE
    PRINT N'SyncApply_TransferDetail OK or Generic missing.';
GO

IF OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) NOT LIKE N'%hardDeleteDetail%'
    PRINT N'WARNING: run DataSync_10_SyncApply_Generic.sql on CLOUD';
ELSE
    PRINT N'SyncApply_Generic hardDeleteDetail OK';
GO

PRINT N'=== DONE ===';
GO
