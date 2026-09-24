/*
  Seed SyncOutbox — SAFE batched version (avoids SQL Server hang on large tables).

  Run on LOCAL ONLY.

  IMPORTANT:
  - Do NOT seed tables already in SyncOutbox (SaleHead, SaleDetail, etc.)
  - Script creates procs ONLY — run seed separately (see bottom)
  - Use small batches; repeat until RowsSeeded = 0

  SSMS: run this file to create procs, then run seed commands below.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.SyncSeed_Table', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncSeed_Table;
GO

CREATE PROCEDURE dbo.SyncSeed_Table
    @TableName           sysname,
    @Reseed              bit = 0,
    @BatchSize           int = 200,
    @MaxRows             int = NULL,
    @SkipIfOutboxExists  bit = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @BatchSize < 1 OR @BatchSize > 5000 SET @BatchSize = 200;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.SyncConfig
        WHERE TableName = @TableName AND IsEnabled = 1 AND CaptureLocal = 1
    )
    BEGIN
        PRINT N'SKIP ' + @TableName + N' (not enabled)';
        RETURN;
    END

    DECLARE @obj int = OBJECT_ID(QUOTENAME(@TableName));
    IF @obj IS NULL
    BEGIN
        PRINT N'SKIP ' + @TableName + N' (missing)';
        RETURN;
    END

    IF @SkipIfOutboxExists = 1 AND @Reseed = 0
       AND EXISTS (SELECT 1 FROM dbo.SyncOutbox WHERE Direction = N'L2C' AND TableName = @TableName)
    BEGIN
        PRINT N'SKIP ' + @TableName + N' (outbox already has rows — agent draining)';
        RETURN;
    END

    DECLARE @pk sysname;
    SELECT TOP 1 @pk = c.name
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @obj AND i.is_primary_key = 1
    ORDER BY ic.key_ordinal;

    IF @pk IS NULL
    BEGIN
        PRINT N'SKIP ' + @TableName + N' (no single PK)';
        RETURN;
    END

    DECLARE @jsonCols nvarchar(max);
    SELECT @jsonCols = STRING_AGG(
        CASE
            WHEN c.name = 'IsDeleted' THEN N'IsDeleted = ISNULL(t.IsDeleted, 0)'
            WHEN c.name = 'Deleted' THEN N'Deleted = ISNULL(t.Deleted, 0)'
            ELSE N't.' + QUOTENAME(c.name)
        END, N', ')
    FROM sys.columns c
    WHERE c.object_id = @obj
      AND c.is_computed = 0
      AND c.system_type_id NOT IN (34, 35, 99, 189)
      AND c.name <> 'SyncRowVersion';

    DECLARE @pkJsonPath nvarchar(200) = N'$.' + @pk;
    DECLARE @total int = 0, @batch int = 0, @limit int = ISNULL(@MaxRows, 2147483647);

    EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;

    WHILE @total < @limit
    BEGIN
        DECLARE @take int = CASE WHEN @limit - @total < @BatchSize THEN @limit - @total ELSE @BatchSize END;
        DECLARE @sql nvarchar(max) = N'
INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
SELECT TOP (@take)
    N''L2C'', @TableName,
    (SELECT t.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    N''I'',
    (SELECT ' + @jsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    ISNULL(t.SyncModifiedAt, sysutcdatetime())
FROM ' + QUOTENAME(@TableName) + N' t
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.SyncOutbox o
    WHERE o.Direction = N''L2C'' AND o.TableName = @TableName
      AND JSON_VALUE(o.PrimaryKeyJson, @pkPath) = CONVERT(nvarchar(50), t.' + QUOTENAME(@pk) + N')
      AND (o.Status IN (N''Pending'', N''Syncing'') OR (@Reseed = 0 AND o.Status = N''Synced''))
);';

        EXEC sp_executesql @sql,
            N'@take int, @TableName sysname, @pkPath nvarchar(200), @Reseed bit',
            @take = @take, @TableName = @TableName, @pkPath = @pkJsonPath, @Reseed = @Reseed;

        SET @batch = @@ROWCOUNT;
        SET @total += @batch;
        IF @batch = 0 BREAK;
    END

    EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;

    SELECT @TableName AS TableName, @total AS RowsSeeded;
END
GO

IF OBJECT_ID('dbo.SyncSeed_AllTables', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncSeed_AllTables;
GO

CREATE PROCEDURE dbo.SyncSeed_AllTables
    @Reseed              bit = 0,
    @BatchSize           int = 200,
    @MaxRowsPerTable     int = NULL,
    @SkipIfOutboxExists  bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @t sysname;

    DECLARE seed_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT TableName FROM dbo.SyncConfig
        WHERE IsEnabled = 1 AND CaptureLocal = 1
        ORDER BY Priority, TableName;

    OPEN seed_cursor;
    FETCH NEXT FROM seed_cursor INTO @t;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.SyncSeed_Table
                @TableName = @t, @Reseed = @Reseed, @BatchSize = @BatchSize,
                @MaxRows = @MaxRowsPerTable, @SkipIfOutboxExists = @SkipIfOutboxExists;
        END TRY
        BEGIN CATCH
            PRINT N'WARN ' + @t + N': ' + ERROR_MESSAGE();
        END CATCH
        FETCH NEXT FROM seed_cursor INTO @t;
    END
    CLOSE seed_cursor;
    DEALLOCATE seed_cursor;
END
GO

IF OBJECT_ID('dbo.SyncSeed_NewTablesOnly', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncSeed_NewTablesOnly;
GO

CREATE PROCEDURE dbo.SyncSeed_NewTablesOnly
    @BatchSize int = 200
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @t sysname;

    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT c.TableName
        FROM dbo.SyncConfig c
        WHERE c.IsEnabled = 1 AND c.CaptureLocal = 1
          AND NOT EXISTS (
              SELECT 1 FROM dbo.SyncOutbox o
              WHERE o.Direction = N'L2C' AND o.TableName = c.TableName
          )
        ORDER BY c.Priority, c.TableName;

    OPEN c;
    FETCH NEXT FROM c INTO @t;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'Seeding new table: ' + @t;
        EXEC dbo.SyncSeed_Table @TableName = @t, @BatchSize = @BatchSize,
             @SkipIfOutboxExists = 0, @MaxRows = NULL;
        FETCH NEXT FROM c INTO @t;
    END
    CLOSE c;
    DEALLOCATE c;
END
GO

PRINT 'Procs created. Do NOT run full seed on all tables if Sale/Purchase pending exists.';
PRINT 'Safe command — NEW tables only (RawIssue, FinishGoods, etc.):';
PRINT '  EXEC dbo.SyncSeed_NewTablesOnly @BatchSize = 200;';
PRINT 'Single table:';
PRINT '  EXEC dbo.SyncSeed_Table @TableName = N''RawIssueHead'', @BatchSize = 200, @SkipIfOutboxExists = 0;';
GO
