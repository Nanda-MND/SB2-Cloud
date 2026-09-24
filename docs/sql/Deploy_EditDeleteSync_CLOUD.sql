/*
  ============================================================================
  CLOUD ONLY — Head soft-delete + Detail hard-delete sync finish
  ============================================================================
  Prerequisites (MUST already be done on THIS Cloud DB):
    docs/sql/DataSync_10_SyncApply_Generic.sql
    → markers: hardDeleteDetail + preserve-soft-delete-flags

  Run AFTER Deploy_EditDeleteSync_LOCAL.sql on Local.
  Then rebuild SyncAgent on client.

  Safe: wrong-DB stop; SyncApply marker gate + SET NOEXEC;
  cleanup/requeue failures PRINT only (no cascade abort).
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'Deploy Edit/Delete sync — CLOUD';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME;
PRINT N'============================================================';

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    BEGIN TRY EXEC sp_set_session_context @key = N'EditDeleteSyncDeployOK', @value = 0; END TRY BEGIN CATCH END CATCH;
    RAISERROR(N'STOP: This is LOCAL. Use Deploy_EditDeleteSync_LOCAL.sql instead.', 16, 1);
    RETURN;
END
GO

/* ---------- 0) SyncApply must be complete ---------- */
PRINT N'--- 0) SyncApply_Generic markers ---';
IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    BEGIN TRY EXEC sp_set_session_context @key = N'EditDeleteSyncDeployOK', @value = 0; END TRY BEGIN CATCH END CATCH;
    RAISERROR(N'STOP: SyncApply_Generic missing. Run DataSync_10_SyncApply_Generic.sql on CLOUD first.', 16, 1);
    RETURN;
END

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'));
DECLARE @okDetail bit = CASE WHEN @def LIKE N'%hardDeleteDetail%' THEN 1 ELSE 0 END;
DECLARE @okHead bit = CASE WHEN @def LIKE N'%preserve-soft-delete-flags%' THEN 1 ELSE 0 END;

SELECT
    CASE @okDetail WHEN 1 THEN N'OK' ELSE N'MISSING' END AS DetailHardDelete,
    CASE @okHead WHEN 1 THEN N'OK' ELSE N'MISSING' END AS HeadSoftDeletePreserve;

IF @okDetail = 0 OR @okHead = 0
BEGIN
    BEGIN TRY EXEC sp_set_session_context @key = N'EditDeleteSyncDeployOK', @value = 0; END TRY BEGIN CATCH END CATCH;
    RAISERROR(N'STOP: DataSync_10 incomplete on CLOUD. Re-run DataSync_10_SyncApply_Generic.sql then retry this script.', 16, 1);
    RETURN;
END
BEGIN TRY EXEC sp_set_session_context @key = N'EditDeleteSyncDeployOK', @value = 1; END TRY BEGIN CATCH END CATCH;
PRINT N'SyncApply OK (Detail hard-delete + Head soft-delete preserve).';
GO

/* Gate: skip remaining batches if Step 0 failed (GO would otherwise continue). */
IF ISNULL(CONVERT(int, SESSION_CONTEXT(N'EditDeleteSyncDeployOK')), 0) <> 1
BEGIN
    PRINT N'SKIP remaining CLOUD steps (prerequisite failed).';
    SET NOEXEC ON;
END
GO

/* ---------- 1) PurchaseHead/Detail Apply wrappers (@Operation) ---------- */
PRINT N'--- 1) SyncApply_PurchaseHead / PurchaseDetail (@Operation) ---';
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
PRINT N'Purchase Apply wrappers OK.';
GO

/* ---------- 2) Detail: hard-delete IsDeleted=1 ghosts (this DB) ---------- */
PRINT N'--- 2) Detail IsDeleted=1 ghost cleanup ---';
DECLARE @tbl sysname, @sql nvarchar(max), @cnt int;

DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR
SELECT t.name
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'dbo'
WHERE t.name LIKE N'%Detail'
ORDER BY t.name;

OPEN dcur;
FETCH NEXT FROM dcur INTO @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH(N'dbo.' + @tbl, N'IsDeleted') IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT(*) FROM dbo.' + QUOTENAME(@tbl)
                 + N' WHERE ISNULL(IsDeleted,0) = 1';
        BEGIN TRY
            EXEC sp_executesql @sql, N'@c int OUTPUT', @c = @cnt OUTPUT;
            IF @cnt > 0
            BEGIN
                SET @sql = N'DELETE FROM dbo.' + QUOTENAME(@tbl)
                         + N' WHERE ISNULL(IsDeleted,0) = 1';
                BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
                BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;
                EXEC(@sql);
                PRINT N'  ' + @tbl + N' ghosts removed: ' + CAST(@@ROWCOUNT AS nvarchar(20));
                BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
                BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
            END
            ELSE
                PRINT N'  ' + @tbl + N': no ghosts';
        END TRY
        BEGIN CATCH
            PRINT N'  ' + @tbl + N' SKIP: ' + ERROR_MESSAGE();
        END CATCH
    END
    FETCH NEXT FROM dcur INTO @tbl;
END
CLOSE dcur; DEALLOCATE dcur;
GO

/* ---------- 3) Head: mirror Deleted → IsDeleted ---------- */
PRINT N'--- 3) PurchaseHead mirror Deleted → IsDeleted ---';
IF OBJECT_ID(N'dbo.PurchaseHead', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.PurchaseHead', N'Deleted') IS NOT NULL
   AND COL_LENGTH(N'dbo.PurchaseHead', N'IsDeleted') IS NOT NULL
BEGIN
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1; END TRY BEGIN CATCH END CATCH;

    DECLARE @sqlH nvarchar(max) = N'
UPDATE dbo.PurchaseHead
SET IsDeleted = 1';
    IF COL_LENGTH(N'dbo.PurchaseHead', N'DeletedAt') IS NOT NULL
        SET @sqlH += N', DeletedAt = COALESCE(DeletedAt, SYSUTCDATETIME())';
    IF COL_LENGTH(N'dbo.PurchaseHead', N'SyncModifiedAt') IS NOT NULL
        SET @sqlH += N', SyncModifiedAt = SYSUTCDATETIME()';
    SET @sqlH += N'
WHERE ISNULL(Deleted,0) <> 0 AND ISNULL(IsDeleted,0) = 0';

    BEGIN TRY
        EXEC(@sqlH);
        PRINT N'PurchaseHead mirrored: ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END TRY
    BEGIN CATCH
        PRINT N'PurchaseHead mirror SKIP: ' + ERROR_MESSAGE();
    END CATCH

    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
    BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL; END TRY BEGIN CATCH END CATCH;
END
ELSE
    PRINT N'Skip Head mirror (table/columns missing).';
GO

/* ---------- 4) CLOUD C2L requeue Head Op=D + Detail Op=D ---------- */
PRINT N'--- 4) CLOUD C2L requeue soft-delete Heads + Detail deletes ---';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NULL
    PRINT N'No SyncOutbox — skip requeue.';
ELSE
BEGIN
    BEGIN TRY
        UPDATE dbo.SyncOutbox
        SET Status = N'Pending', AttemptCount = 0, LastError = NULL,
            SyncedAt = NULL, SyncModifiedAt = SYSUTCDATETIME()
        WHERE Direction = N'C2L'
          AND TableName LIKE N'%Head'
          AND Operation = N'D'
          AND Status IN (N'Synced', N'Conflict', N'DeadLetter', N'Syncing')
          AND CreatedAt >= DATEADD(day, -60, SYSUTCDATETIME());
        PRINT N'C2L *Head Op=D requeued: ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END TRY
    BEGIN CATCH
        PRINT N'C2L Head requeue SKIP: ' + ERROR_MESSAGE();
    END CATCH

    BEGIN TRY
        UPDATE dbo.SyncOutbox
        SET Status = N'Pending', AttemptCount = 0, LastError = NULL,
            SyncedAt = NULL, SyncModifiedAt = SYSUTCDATETIME()
        WHERE Direction = N'C2L'
          AND TableName LIKE N'%Detail'
          AND Operation = N'D'
          AND Status IN (N'Synced', N'Conflict', N'DeadLetter', N'Syncing')
          AND CreatedAt >= DATEADD(day, -30, SYSUTCDATETIME());
        PRINT N'C2L *Detail Op=D requeued: ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END TRY
    BEGIN CATCH
        PRINT N'C2L Detail requeue SKIP: ' + ERROR_MESSAGE();
    END CATCH

    IF OBJECT_ID(N'dbo.PurchaseHead', N'U') IS NOT NULL
    BEGIN
        BEGIN TRY
            DELETE FROM dbo.SyncOutbox
            WHERE Direction = N'C2L' AND TableName = N'PurchaseHead'
              AND Status = N'Pending' AND Operation = N'D';

            INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
            SELECT
                N'C2L', N'PurchaseHead',
                (SELECT h.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                N'D',
                (SELECT h.ID,
                        Deleted = ISNULL(h.Deleted, 1),
                        IsDeleted = CAST(1 AS bit),
                        SyncModifiedAt = ISNULL(h.SyncModifiedAt, SYSUTCDATETIME()),
                        SyncOrigin = ISNULL(h.SyncOrigin, 2)
                 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                ISNULL(h.SyncModifiedAt, SYSUTCDATETIME())
            FROM dbo.PurchaseHead h
            WHERE ISNULL(h.Deleted, 0) <> 0 OR ISNULL(h.IsDeleted, 0) <> 0;
            PRINT N'Fresh C2L PurchaseHead Op=D: ' + CAST(@@ROWCOUNT AS nvarchar(20));
        END TRY
        BEGIN CATCH
            PRINT N'Fresh PurchaseHead Op=D SKIP: ' + ERROR_MESSAGE();
        END CATCH
    END

    BEGIN TRY
        SELECT Status, TableName, Operation, COUNT(*) Cnt
        FROM dbo.SyncOutbox
        WHERE Direction = N'C2L'
          AND (TableName LIKE N'%Head' OR TableName LIKE N'%Detail')
          AND Operation = N'D'
          AND Status = N'Pending'
        GROUP BY Status, TableName, Operation
        ORDER BY TableName;
    END TRY
    BEGIN CATCH
        PRINT N'Pending summary SKIP: ' + ERROR_MESSAGE();
    END CATCH
END
GO

SET NOEXEC OFF;
PRINT N'============================================================';
IF ISNULL(CONVERT(int, SESSION_CONTEXT(N'EditDeleteSyncDeployOK')), 0) = 1
BEGIN
    PRINT N'CLOUD DONE.';
    PRINT N'NEXT: rebuild SyncAgent + restart on client PC.';
    PRINT N'Verify Local+Cloud soft-deleted Heads / hard-deleted Details.';
END
ELSE
    PRINT N'CLOUD STOPPED early — fix DataSync_10 then re-run this script.';
PRINT N'============================================================';
GO
