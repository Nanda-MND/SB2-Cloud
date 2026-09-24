/*
  ============================================================================
  LOCAL SB1 — cleanup Detail hard-delete sync ghosts (last 2 days)
  ============================================================================
  Scope: yesterday + today (UTC), all *Detail tables.

  Does:
    1) Report IsDeleted=1 ghosts
    2) Hard-DELETE those ghosts (suppress outbox)
    3) List L2C Op=D outbox (Synced/Pending) last 2 days
    4) Generate Cloud DELETE statements for those IDs (orphans still on Cloud)
    5) Requeue L2C Op=D so Agent retries if Cloud apply now fixed

  Prerequisite (recommended first):
    DataSync_10_SyncApply_Generic.sql
    Fix_DetailDelete_Sync_BothSides.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'LOCAL Detail-delete cleanup (last 2 days)';
PRINT N'DB=' + DB_NAME() + N'  Utc=' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126);
PRINT N'============================================================';

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%' OR DB_NAME() LIKE N'%abb%'
BEGIN
    RAISERROR(N'STOP: This is CLOUD. Use Cleanup_DetailDeleteGhosts_2Days_CLOUD.sql', 16, 1);
    RETURN;
END
GO

DECLARE @since datetime2(3) = DATEADD(day, -2, SYSUTCDATETIME());
PRINT N'Window since (UTC): ' + CONVERT(nvarchar(30), @since, 126);
GO

/* ---------- 1) Ghost report + hard delete IsDeleted=1 ---------- */
PRINT N'--- 1) IsDeleted=1 ghosts on *Detail (last 2 days) ---';

DECLARE @since datetime2(3) = DATEADD(day, -2, SYSUTCDATETIME());
DECLARE @tbl sysname, @sql nvarchar(max), @cnt int, @hasIsDel bit, @hasMod bit, @modCol sysname;

DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR
SELECT t.name
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'dbo'
WHERE t.name LIKE N'%Detail'
  AND t.name NOT LIKE N'%History%'
ORDER BY t.name;

OPEN dcur;
FETCH NEXT FROM dcur INTO @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @hasIsDel = CASE WHEN COL_LENGTH(N'dbo.' + @tbl, N'IsDeleted') IS NOT NULL THEN 1 ELSE 0 END;
    IF @hasIsDel = 0
    BEGIN
        PRINT N'  ' + @tbl + N': no IsDeleted — skip';
        FETCH NEXT FROM dcur INTO @tbl;
        CONTINUE;
    END

    SET @modCol = CASE
        WHEN COL_LENGTH(N'dbo.' + @tbl, N'SyncModifiedAt') IS NOT NULL THEN N'SyncModifiedAt'
        WHEN COL_LENGTH(N'dbo.' + @tbl, N'SyncModifiedAt') IS NOT NULL THEN N'SyncModifiedAt'
        WHEN COL_LENGTH(N'dbo.' + @tbl, N'DeletedAt') IS NOT NULL THEN N'DeletedAt'
        ELSE NULL END;

    SET @sql = N'SELECT @c = COUNT(*) FROM dbo.' + QUOTENAME(@tbl)
             + N' WHERE ISNULL(IsDeleted,0)=1';
    IF @modCol IS NOT NULL
        SET @sql += N' AND ' + QUOTENAME(@modCol) + N' >= @since';

    BEGIN TRY
        EXEC sp_executesql @sql, N'@c int OUTPUT, @since datetime2(3)', @c=@cnt OUTPUT, @since=@since;
        IF @cnt > 0
        BEGIN
            BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
            BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;

            SET @sql = N'DELETE FROM dbo.' + QUOTENAME(@tbl) + N' WHERE ISNULL(IsDeleted,0)=1';
            IF @modCol IS NOT NULL
                SET @sql += N' AND ' + QUOTENAME(@modCol) + N' >= @since';
            EXEC sp_executesql @sql, N'@since datetime2(3)', @since=@since;
            PRINT N'  ' + @tbl + N' ghosts hard-deleted: ' + CAST(@@ROWCOUNT AS nvarchar(20));

            BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
            BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
        END
        ELSE
            PRINT N'  ' + @tbl + N': 0 ghosts';
    END TRY
    BEGIN CATCH
        PRINT N'  ' + @tbl + N' SKIP: ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM dcur INTO @tbl;
END
CLOSE dcur; DEALLOCATE dcur;
GO

/* ---------- 2) L2C Op=D outbox last 2 days ---------- */
PRINT N'--- 2) Local L2C *Detail Op=D outbox (last 2 days) ---';
DECLARE @since datetime2(3) = DATEADD(day, -2, SYSUTCDATETIME());

SELECT TableName, Status, COUNT(*) Cnt,
       MIN(CreatedAt) Oldest, MAX(CreatedAt) Newest
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName LIKE N'%Detail'
  AND Operation = N'D'
  AND CreatedAt >= @since
GROUP BY TableName, Status
ORDER BY TableName, Status;

SELECT TOP 200 OutboxID, TableName, Status, AttemptCount, PrimaryKeyJson,
       LEFT(ISNULL(LastError,N''), 80) Err, CreatedAt, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName LIKE N'%Detail'
  AND Operation = N'D'
  AND CreatedAt >= @since
ORDER BY OutboxID DESC;
GO

/* ---------- 3) Generate CLOUD DELETE script from Local Op=D ---------- */
PRINT N'--- 3) COPY the SqlBatch below → run on CLOUD ---';
DECLARE @since datetime2(3) = DATEADD(day, -2, SYSUTCDATETIME());

;WITH dels AS (
    SELECT DISTINCT
        o.TableName,
        IdVal = TRY_CAST(JSON_VALUE(o.PrimaryKeyJson, N'$.ID') AS bigint)
    FROM dbo.SyncOutbox o
    WHERE o.Direction = N'L2C'
      AND o.TableName LIKE N'%Detail'
      AND o.Operation = N'D'
      AND o.CreatedAt >= @since
      AND TRY_CAST(JSON_VALUE(o.PrimaryKeyJson, N'$.ID') AS bigint) IS NOT NULL
)
SELECT
    SqlBatch =
      N'BEGIN TRY EXEC sp_set_session_context @key=N''SyncSuppressOutbox'', @value=1; END TRY BEGIN CATCH END CATCH;'
    + N' BEGIN TRY EXEC sp_set_session_context @key=N''SyncAllowPhysicalDelete'', @value=1; END TRY BEGIN CATCH END CATCH;'
    + N' DELETE FROM dbo.' + QUOTENAME(TableName)
    + N' WHERE ID IN (' + STRING_AGG(CAST(IdVal AS nvarchar(30)), N',') WITHIN GROUP (ORDER BY IdVal) + N');'
    + N' PRINT N''' + TableName + N' deleted: '' + CAST(@@ROWCOUNT AS nvarchar(20));'
    + N' BEGIN TRY EXEC sp_set_session_context @key=N''SyncSuppressOutbox'', @value=NULL; END TRY BEGIN CATCH END CATCH;'
    + N' BEGIN TRY EXEC sp_set_session_context @key=N''SyncAllowPhysicalDelete'', @value=NULL; END TRY BEGIN CATCH END CATCH;'
FROM dels
GROUP BY TableName
ORDER BY TableName;
GO

/* ---------- 4) Requeue L2C Op=D ---------- */
PRINT N'--- 4) Requeue L2C *Detail Op=D (last 2 days) ---';
DECLARE @since datetime2(3) = DATEADD(day, -2, SYSUTCDATETIME());

UPDATE dbo.SyncOutbox
SET Status = N'Pending',
    AttemptCount = 0,
    LastError = NULL,
    SyncedAt = NULL,
    SyncModifiedAt = SYSUTCDATETIME()
WHERE Direction = N'L2C'
  AND TableName LIKE N'%Detail'
  AND Operation = N'D'
  AND Status IN (N'Synced', N'Conflict', N'DeadLetter', N'Syncing')
  AND CreatedAt >= @since;
PRINT N'Requeued: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'============================================================';
PRINT N'LOCAL DONE.';
PRINT N'1) Copy SqlBatch from result grid #3 → run on CLOUD';
PRINT N'2) Also run Cleanup_DetailDeleteGhosts_2Days_CLOUD.sql on CLOUD';
PRINT N'3) Keep SyncAgent running';
PRINT N'============================================================';
GO
