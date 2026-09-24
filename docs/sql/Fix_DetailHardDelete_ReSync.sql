/*
  ============================================================================
  Detail hard-delete re-sync
  ============================================================================
  Run AFTER both sides have:
    docs/sql/DataSync_10_SyncApply_Generic.sql
  (must contain hardDeleteDetail)

  Order:
    1) LOCAL SB1  — this script
    2) CLOUD      — this script
    3) SyncAgent running
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'Detail hard-delete re-sync';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME;
PRINT N'============================================================';
GO

/* A) SyncApply must hard-delete *Detail */
PRINT N'--- A) SyncApply_Generic version ---';
IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    RAISERROR(N'STOP: SyncApply_Generic missing. Run DataSync_10_SyncApply_Generic.sql first.', 16, 1);
    RETURN;
END

SELECT
    CASE
        WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
             LIKE N'%hardDeleteDetail%'
            THEN N'OK_HARD_DELETE_DETAIL'
        ELSE N'OLD — redeploy DataSync_10_SyncApply_Generic.sql'
    END AS ApplyVer;
GO

IF OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) NOT LIKE N'%hardDeleteDetail%'
BEGIN
    RAISERROR(N'STOP: SyncApply lacks hardDeleteDetail. Deploy DataSync_10 first.', 16, 1);
    RETURN;
END
GO

/* B) Physical cleanup of IsDeleted=1 ghosts on *Detail (this DB) */
PRINT N'--- B) Hard-delete IsDeleted=1 ghosts on *Detail ---';

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
        EXEC sp_executesql @sql, N'@c int OUTPUT', @c = @cnt OUTPUT;

        IF @cnt > 0
        BEGIN
            SET @sql = N'DELETE FROM dbo.' + QUOTENAME(@tbl)
                     + N' WHERE ISNULL(IsDeleted,0) = 1';
            BEGIN TRY
                EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
                EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1;
                EXEC(@sql);
                PRINT N'  ' + @tbl + N' ghosts hard-deleted: ' + CAST(@@ROWCOUNT AS nvarchar(20));
            END TRY
            BEGIN CATCH
                PRINT N'  ' + @tbl + N' FAIL: ' + ERROR_MESSAGE();
            END CATCH
            BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
            BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
        END
        ELSE
            PRINT N'  ' + @tbl + N': no IsDeleted=1 ghosts';
    END
    FETCH NEXT FROM dcur INTO @tbl;
END
CLOSE dcur;
DEALLOCATE dcur;
GO

/* C) CLOUD — requeue recent *Detail Operation=D so Agent hard-deletes on Local */
PRINT N'--- C) Requeue C2L Op=D (*Detail, last 30 days) ---';

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    PRINT N'Skip C on Local. Run this script on Cloud for requeue.';
END
ELSE IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NULL
BEGIN
    PRINT N'No SyncOutbox — skip C.';
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
      AND CreatedAt >= DATEADD(day, -30, SYSUTCDATETIME());

    PRINT N'Requeued C2L *Detail Op=D: ' + CAST(@@ROWCOUNT AS nvarchar(20));

    SELECT Status, TableName, Operation, COUNT(*) AS Cnt
    FROM dbo.SyncOutbox
    WHERE Direction = N'C2L'
      AND TableName LIKE N'%Detail'
      AND Operation = N'D'
      AND CreatedAt >= DATEADD(day, -30, SYSUTCDATETIME())
    GROUP BY Status, TableName, Operation
    ORDER BY TableName, Status;
END
GO

PRINT N'============================================================';
PRINT N'DONE. Keep SyncAgent running.';
PRINT N'Verify: open Purchase — deleted detail lines must be gone.';
PRINT N'============================================================';
GO
