/*
  Delta seed — queue rows changed since backup time (Local only).

  Prerequisite:
  - DataSync_13_InitialSeed.sql procs installed (SyncSeed_Table exists)
  - Local outbox cleared (LocalToCloudRestore_03)
  - @Since = exact backup FINISH time (T0)

  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -v Since="2026-07-21 06:00:00" -i LocalToCloudRestore_04_DeltaSeed.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.SyncSeed_DeltaSince', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncSeed_DeltaSince;
GO

CREATE PROCEDURE dbo.SyncSeed_DeltaSince
    @Since     datetime2(3),
    @BatchSize int = 500
AS
BEGIN
    SET NOCOUNT ON;
    IF @Since IS NULL
    BEGIN
        RAISERROR(N'@Since (backup finish time) is required.', 16, 1);
        RETURN;
    END

    DECLARE @t sysname, @total bigint = 0, @n int;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT TableName FROM dbo.SyncConfig
        WHERE IsEnabled = 1 AND CaptureLocal = 1
        ORDER BY Priority, TableName;

    OPEN c;
    FETCH NEXT FROM c INTO @t;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.SyncSeed_DeltaSince_Table @TableName = @t, @Since = @Since, @BatchSize = @BatchSize;
        END TRY
        BEGIN CATCH
            PRINT N'WARN ' + @t + N': ' + ERROR_MESSAGE();
        END CATCH
        FETCH NEXT FROM c INTO @t;
    END
    CLOSE c;
    DEALLOCATE c;

    PRINT N'Delta seed since ' + CONVERT(nvarchar(30), @Since, 126);
    SELECT TableName, COUNT(*) AS PendingRows
    FROM dbo.SyncOutbox WHERE Direction = N'L2C' AND Status = N'Pending'
    GROUP BY TableName ORDER BY PendingRows DESC;

    SELECT COUNT(*) AS TotalPending FROM dbo.SyncOutbox WHERE Direction = N'L2C' AND Status = N'Pending';
END
GO

IF OBJECT_ID(N'dbo.SyncSeed_DeltaSince_Table', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncSeed_DeltaSince_Table;
GO

CREATE PROCEDURE dbo.SyncSeed_DeltaSince_Table
    @TableName sysname,
    @Since     datetime2(3),
    @BatchSize int = 500
AS
BEGIN
    SET NOCOUNT ON;

    IF COL_LENGTH(@TableName, N'SyncModifiedAt') IS NULL
    BEGIN
        PRINT N'SKIP ' + @TableName + N' (no SyncModifiedAt)';
        RETURN;
    END

    DECLARE @obj int = OBJECT_ID(QUOTENAME(@TableName));
    IF @obj IS NULL RETURN;

    DECLARE @pk sysname;
    SELECT TOP 1 @pk = c.name
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @obj AND i.is_primary_key = 1
    ORDER BY ic.key_ordinal;

    IF @pk IS NULL RETURN;

    DECLARE @jsonCols nvarchar(max);
    SELECT @jsonCols = STRING_AGG(
        CASE
            WHEN c.name = N'IsDeleted' THEN N'IsDeleted = ISNULL(t.IsDeleted, 0)'
            WHEN c.name = N'Deleted' THEN N'Deleted = ISNULL(t.Deleted, 0)'
            ELSE N't.' + QUOTENAME(c.name)
        END, N', ')
    FROM sys.columns c
    WHERE c.object_id = @obj
      AND c.is_computed = 0
      AND c.system_type_id NOT IN (34, 35, 99, 189)
      AND c.name <> N'SyncRowVersion';

    DECLARE @pkJsonPath nvarchar(200) = N'$.' + @pk;
    DECLARE @total int = 0, @batch int;

    EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;

    WHILE 1 = 1
    BEGIN
        DECLARE @sql nvarchar(max) = N'
INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
SELECT TOP (@take)
    N''L2C'', @TableName,
    (SELECT t.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    N''U'',
    (SELECT ' + @jsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    t.SyncModifiedAt
FROM ' + QUOTENAME(@TableName) + N' t
WHERE t.SyncModifiedAt >= @Since
  AND NOT EXISTS (
    SELECT 1 FROM dbo.SyncOutbox o
    WHERE o.Direction = N''L2C'' AND o.TableName = @TableName
      AND JSON_VALUE(o.PrimaryKeyJson, @pkPath) = CONVERT(nvarchar(50), t.' + QUOTENAME(@pk) + N')
);';

        EXEC sp_executesql @sql,
            N'@take int, @TableName sysname, @pkPath nvarchar(200), @Since datetime2(3)',
            @take = @BatchSize, @TableName = @TableName, @pkPath = @pkJsonPath, @Since = @Since;

        SET @batch = @@ROWCOUNT;
        SET @total += @batch;
        IF @batch = 0 BREAK;
    END

    EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;

    SELECT @TableName AS TableName, @total AS RowsSeeded;
END
GO

-- Run (edit @Since to backup finish time):
/*
DECLARE @T0 datetime2(3) = '2026-07-21 06:00:00';  -- <<< BACKUP FINISH TIME
EXEC dbo.SyncSeed_DeltaSince @Since = @T0, @BatchSize = 500;
*/
GO
