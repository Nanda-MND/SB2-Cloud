/*
  Cloud → Local (C2L) capture — install on CLOUD only.

  Prerequisite: DataSync_01 schema + SyncOutbox on Cloud (from restore).
  Local: L2C capture unchanged. Cloud: C2L outbox triggers only.

  Pilot tables (edit on Cloud web / admin): enable in @C2LTables below.

  sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P xxx -C -I -i DataSync_28_EnableC2L_Capture.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncInstall_CloudCapture;
GO

CREATE PROCEDURE dbo.SyncInstall_CloudCapture
    @TableName sysname
AS
BEGIN
    SET NOCOUNT ON;

    IF @TableName LIKE N'Sync%' RETURN;

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

    DECLARE @isDetail bit = CASE WHEN @TableName LIKE N'%Detail' THEN 1 ELSE 0 END;
    DECLARE @hasDeleted bit = CASE WHEN COL_LENGTH(@TableName, N'Deleted') IS NOT NULL THEN 1 ELSE 0 END;
    DECLARE @sql nvarchar(max);

    DECLARE @jsonCols nvarchar(max) = N'';
    SELECT @jsonCols = STRING_AGG(
        CASE
            WHEN c.name = N'IsDeleted' THEN N'IsDeleted = ISNULL(i.IsDeleted, 0)'
            WHEN c.name = N'Deleted' THEN N'Deleted = ISNULL(i.Deleted, 0)'
            ELSE N'i.' + QUOTENAME(c.name)
        END, N', ')
    FROM sys.columns c
    WHERE c.object_id = @obj
      AND c.is_computed = 0
      AND c.system_type_id NOT IN (34, 35, 99, 189)
      AND c.name <> N'SyncRowVersion';

    DECLARE @delJsonCols nvarchar(max) = N'd.' + QUOTENAME(@pk);
    IF COL_LENGTH(@TableName, N'RefID') IS NOT NULL SET @delJsonCols += N', d.RefID';
    IF COL_LENGTH(@TableName, N'Sr') IS NOT NULL SET @delJsonCols += N', d.Sr';
    IF COL_LENGTH(@TableName, N'CodeID') IS NOT NULL AND @delJsonCols NOT LIKE N'%CodeID%' SET @delJsonCols += N', d.CodeID';

    DECLARE @triggerEvents nvarchar(30) = CASE WHEN @isDetail = 1 THEN N'INSERT, UPDATE, DELETE' ELSE N'INSERT, UPDATE' END;
    DECLARE @opCase nvarchar(max) = N'CASE WHEN d.' + QUOTENAME(@pk) + N' IS NULL THEN ''I''';
    IF COL_LENGTH(@TableName, N'IsDeleted') IS NOT NULL
        SET @opCase += N' WHEN ISNULL(i.IsDeleted,0)=1 AND ISNULL(d.IsDeleted,0)=0 THEN ''D''';
    IF @hasDeleted = 1
        SET @opCase += N' WHEN ISNULL(i.Deleted,0)<>0 AND ISNULL(d.Deleted,0)=0 THEN ''D''';
    SET @opCase += N' ELSE ''U'' END';

    IF OBJECT_ID(N'dbo.tr_SyncOutbox_' + @TableName, N'TR') IS NOT NULL
        EXEC(N'DROP TRIGGER dbo.tr_SyncOutbox_' + @TableName);

    SET @sql = N'CREATE TRIGGER dbo.tr_SyncOutbox_' + @TableName + N'
ON ' + QUOTENAME(@TableName) + N'
AFTER ' + @triggerEvents + N'
AS
BEGIN
    SET NOCOUNT ON;
    IF SESSION_CONTEXT(N''SyncSuppressOutbox'') = 1 RETURN;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.SyncConfig
        WHERE TableName = N''' + @TableName + N''' AND IsEnabled = 1 AND CaptureCloud = 1
    ) RETURN;

    ;WITH changed AS (
        SELECT src.' + QUOTENAME(@pk) + N', src.Operation, src.PayloadJson, src.PrimaryKeyJson, src.SyncModifiedAt FROM (
            SELECT i.' + QUOTENAME(@pk) + N',
                Operation = ' + @opCase + N',
                PayloadJson = (SELECT ' + @jsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                PrimaryKeyJson = (SELECT i.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
            FROM inserted i LEFT JOIN deleted d ON d.' + QUOTENAME(@pk) + N' = i.' + QUOTENAME(@pk);
    IF @isDetail = 1
        SET @sql += N'
            UNION ALL
            SELECT d.' + QUOTENAME(@pk) + N', ''D'',
                (SELECT ' + @delJsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                (SELECT d.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                sysutcdatetime()
            FROM deleted d WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.' + QUOTENAME(@pk) + N' = d.' + QUOTENAME(@pk) + N')';
    SET @sql += N'
        ) src
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT ''C2L'', N''' + @TableName + N''', c.PrimaryKeyJson, c.Operation, c.PayloadJson, c.SyncModifiedAt
    FROM changed c
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.SyncOutbox o
        WHERE o.Direction = ''C2L'' AND o.TableName = N''' + @TableName + N'''
          AND o.PrimaryKeyJson = c.PrimaryKeyJson AND o.Status = N''Pending''
          AND o.CreatedAt > DATEADD(second, -1, sysutcdatetime())
    );
END';
    EXEC sp_executesql @sql;

    -- Upsert: UPDATE alone leaves CaptureCloud=0 when SyncConfig row is missing
    -- (trigger checks CaptureCloud=1 and never writes C2L outbox).
    IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = @TableName)
        UPDATE dbo.SyncConfig
        SET CaptureCloud = 1, CaptureLocal = 0, IsEnabled = 1
        WHERE TableName = @TableName;
    ELSE
        INSERT INTO dbo.SyncConfig
            (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
        VALUES
            (@TableName, 1, 0, 1, N'ID', 100, 50, N'C2L via SyncInstall_CloudCapture');

    PRINT N'C2L capture installed: ' + @TableName;
END
GO

-- ========== Pilot C2L tables (Cloud edits only — ~1/100 of L2C volume) ==========
-- UserRights intentionally omitted: L2C only (see DataSync_UserRights_L2C_Only.sql).
DECLARE @C2LTables TABLE (TableName sysname PRIMARY KEY);
INSERT @C2LTables (TableName) VALUES
    (N'Setting'),
    (N'Users'),
    (N'Location'),
    (N'Customer');
-- Add more when Cloud web app writes them

DECLARE @t sysname;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @C2LTables;
OPEN c;
FETCH NEXT FROM c INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC dbo.SyncInstall_CloudCapture @TableName = @t; -- same proc as CREATE above
    END TRY
    BEGIN CATCH
        PRINT N'WARN ' + @t + N': ' + ERROR_MESSAGE();
    END CATCH
    FETCH NEXT FROM c INTO @t;
END
CLOSE c;
DEALLOCATE c;

PRINT '=== C2L verify ===';
SELECT c.TableName, c.IsEnabled, c.CaptureLocal, c.CaptureCloud
FROM dbo.SyncConfig c
INNER JOIN @C2LTables t ON t.TableName = c.TableName;

SELECT COUNT(*) AS C2LCaptureTriggers
FROM sys.triggers WHERE name LIKE N'tr_SyncOutbox_%';
GO
