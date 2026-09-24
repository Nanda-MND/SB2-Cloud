/*
  Install sync columns, metadata triggers, outbox capture, and SyncConfig
  for ALL dbo user tables with a single-column primary key.

  Run on BOTH Local and Cloud for schema + SyncConfig.
  Run with InstallCapture=1 on LOCAL ONLY for outbox triggers.

  sqlcmd -v InstallCapture=1   (Local)
  sqlcmd -v InstallCapture=0   (Cloud)
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.SyncInstall_Table', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncInstall_Table;
GO

CREATE PROCEDURE dbo.SyncInstall_Table
    @TableName      sysname,
    @InstallCapture bit = 0,
    @Priority       tinyint = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @TableName LIKE 'Sync%' OR @TableName IN ('sysdiagrams', 'dtproperties', '__EFMigrationsHistory', '__MigrationHistory')
        RETURN;

    DECLARE @obj int = OBJECT_ID(QUOTENAME(@TableName));
    IF @obj IS NULL
        RETURN;

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes i
        WHERE i.object_id = @obj AND i.is_primary_key = 1
        GROUP BY i.object_id
        HAVING COUNT(*) = 1
    )
        RETURN;

    DECLARE @pk sysname;
    SELECT TOP 1 @pk = c.name
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE i.object_id = @obj AND i.is_primary_key = 1
    ORDER BY ic.key_ordinal;

    DECLARE @hasDeleted bit = CASE WHEN COL_LENGTH(@TableName, 'Deleted') IS NOT NULL THEN 1 ELSE 0 END;
    DECLARE @hasIsDeleted bit = CASE WHEN COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL THEN 1 ELSE 0 END;
    DECLARE @isDetail bit = CASE WHEN @TableName LIKE '%Detail' THEN 1 ELSE 0 END;

    IF @Priority IS NULL
        SET @Priority = CASE
            WHEN @isDetail = 1 THEN 45
            WHEN @TableName LIKE '%Head' THEN 40
            WHEN @TableName LIKE '%Opening%' THEN 42
            ELSE 30
        END;

    -- Sync columns
    DECLARE @sql nvarchar(max);

    IF COL_LENGTH(@TableName, 'IsDeleted') IS NULL AND @hasDeleted = 1
    BEGIN
        SET @sql = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD IsDeleted bit NOT NULL CONSTRAINT DF_' + @TableName + N'_IsDeleted DEFAULT (0);';
        EXEC sp_executesql @sql;
    END

    IF COL_LENGTH(@TableName, 'DeletedAt') IS NULL AND (@hasDeleted = 1 OR @hasIsDeleted = 1)
    BEGIN
        SET @sql = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD DeletedAt datetime2(3) NULL;';
        EXEC sp_executesql @sql;
    END

    IF COL_LENGTH(@TableName, 'DeletedBy') IS NULL AND (@hasDeleted = 1 OR @hasIsDeleted = 1)
    BEGIN
        SET @sql = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD DeletedBy int NULL;';
        EXEC sp_executesql @sql;
    END

    IF COL_LENGTH(@TableName, 'SyncModifiedAt') IS NULL
    BEGIN
        SET @sql = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD SyncModifiedAt datetime2(3) NOT NULL CONSTRAINT DF_' + @TableName + N'_SyncMod DEFAULT (sysutcdatetime());';
        EXEC sp_executesql @sql;
    END

    IF COL_LENGTH(@TableName, 'SyncModifiedBy') IS NULL
    BEGIN
        SET @sql = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD SyncModifiedBy int NULL;';
        EXEC sp_executesql @sql;
    END

    IF COL_LENGTH(@TableName, 'SyncOrigin') IS NULL
    BEGIN
        SET @sql = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD SyncOrigin tinyint NOT NULL CONSTRAINT DF_' + @TableName + N'_SyncOrigin DEFAULT (1);';
        EXEC sp_executesql @sql;
    END

    IF COL_LENGTH(@TableName, 'SyncRowVersion') IS NULL
    BEGIN
        SET @sql = N'ALTER TABLE ' + QUOTENAME(@TableName) + N' ADD SyncRowVersion rowversion;';
        EXEC sp_executesql @sql;
    END

    IF @hasDeleted = 1 AND COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL
    BEGIN
        SET @sql = N'
EXEC sp_set_session_context @key = N''SyncSuppressMetadata'', @value = 1;
EXEC sp_set_session_context @key = N''SyncSuppressOutbox'', @value = 1;
UPDATE t SET IsDeleted = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN 1 ELSE 0 END,
    DeletedAt = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN ISNULL(DeletedAt, SyncModifiedAt) ELSE NULL END
FROM ' + QUOTENAME(@TableName) + N' t
WHERE IsDeleted = 0 AND ISNULL(Deleted, 0) <> 0;
EXEC sp_set_session_context @key = N''SyncSuppressMetadata'', @value = NULL;
EXEC sp_set_session_context @key = N''SyncSuppressOutbox'', @value = NULL;';
        EXEC sp_executesql @sql;
    END

    -- Column list for JSON payload
    DECLARE @jsonCols nvarchar(max) = N'';
    SELECT @jsonCols = STRING_AGG(
        CASE
            WHEN c.name = 'IsDeleted' THEN N'IsDeleted = ISNULL(i.IsDeleted, 0)'
            WHEN c.name = 'Deleted' THEN N'Deleted = ISNULL(i.Deleted, 0)'
            ELSE N'i.' + QUOTENAME(c.name)
        END, N', ')
    FROM sys.columns c
    WHERE c.object_id = @obj
      AND c.is_computed = 0
      AND c.system_type_id NOT IN (34, 35, 99, 189)
      AND c.name <> 'SyncRowVersion';

    DECLARE @delJsonCols nvarchar(max) = N'd.' + QUOTENAME(@pk);
    IF COL_LENGTH(@TableName, 'RefID') IS NOT NULL
        SET @delJsonCols += N', d.RefID';
    IF COL_LENGTH(@TableName, 'Sr') IS NOT NULL
        SET @delJsonCols += N', d.Sr';
    IF COL_LENGTH(@TableName, 'CodeID') IS NOT NULL AND @delJsonCols NOT LIKE N'%CodeID%'
        SET @delJsonCols += N', d.CodeID';

    -- Metadata trigger (DROP and CREATE must be separate batches)
    IF OBJECT_ID(N'dbo.tr_' + @TableName + N'_SyncMetadata', N'TR') IS NOT NULL
        EXEC(N'DROP TRIGGER dbo.tr_' + @TableName + N'_SyncMetadata');

    SET @sql = N'CREATE TRIGGER dbo.tr_' + @TableName + N'_SyncMetadata
ON ' + QUOTENAME(@TableName) + N'
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF SESSION_CONTEXT(N''SyncSuppressMetadata'') = 1 RETURN;
    IF NOT EXISTS (
        SELECT 1 FROM inserted i
        LEFT JOIN deleted d ON d.' + QUOTENAME(@pk) + N' = i.' + QUOTENAME(@pk) + N'
        WHERE d.' + QUOTENAME(@pk) + N' IS NULL
           OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy, -1) = ISNULL(d.SyncModifiedBy, -1))
    ) RETURN;
    EXEC sp_set_session_context @key = N''SyncSuppressMetadata'', @value = 1;
    UPDATE t SET t.SyncModifiedAt = sysutcdatetime(), t.SyncModifiedBy = COALESCE(i.SyncModifiedBy, t.SyncModifiedBy)
    FROM ' + QUOTENAME(@TableName) + N' t
    INNER JOIN inserted i ON i.' + QUOTENAME(@pk) + N' = t.' + QUOTENAME(@pk) + N';
END';
    EXEC sp_executesql @sql;

    -- Soft delete sync (non-detail tables with Deleted column)
    IF @hasDeleted = 1 AND @isDetail = 0 AND COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL
    BEGIN
        IF OBJECT_ID(N'dbo.tr_' + @TableName + N'_SoftDeleteSync', N'TR') IS NOT NULL
            EXEC(N'DROP TRIGGER dbo.tr_' + @TableName + N'_SoftDeleteSync');

        SET @sql = N'CREATE TRIGGER dbo.tr_' + @TableName + N'_SoftDeleteSync
ON ' + QUOTENAME(@TableName) + N'
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF SESSION_CONTEXT(N''SyncSuppressMetadata'') = 1 RETURN;
    IF NOT EXISTS (
        SELECT 1 FROM inserted i INNER JOIN deleted d ON d.' + QUOTENAME(@pk) + N' = i.' + QUOTENAME(@pk) + N'
        WHERE ISNULL(i.Deleted, 0) <> 0 AND ISNULL(d.Deleted, 0) = 0
    ) RETURN;
    EXEC sp_set_session_context @key = N''SyncSuppressMetadata'', @value = 1;
    UPDATE t SET t.IsDeleted = 1,
        t.DeletedAt = COALESCE(t.DeletedAt, i.DeletedAt, sysutcdatetime()),
        t.DeletedBy = COALESCE(t.DeletedBy, i.DeletedBy, i.SyncModifiedBy)
    FROM ' + QUOTENAME(@TableName) + N' t
    INNER JOIN inserted i ON i.' + QUOTENAME(@pk) + N' = t.' + QUOTENAME(@pk) + N'
    WHERE ISNULL(i.Deleted, 0) <> 0 AND ISNULL(t.IsDeleted, 0) = 0;
END';
        EXEC sp_executesql @sql;
    END

    IF @InstallCapture = 1
    BEGIN
        DECLARE @triggerEvents nvarchar(30) = CASE WHEN @isDetail = 1 THEN N'INSERT, UPDATE, DELETE' ELSE N'INSERT, UPDATE' END;
        DECLARE @opCase nvarchar(max) = N'CASE WHEN d.' + QUOTENAME(@pk) + N' IS NULL THEN ''I''';
        IF COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL
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
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N''' + @TableName + N''' AND IsEnabled = 1 AND CaptureLocal = 1) RETURN;

    ;WITH changed AS (
        SELECT src.' + QUOTENAME(@pk) + N', src.Operation, src.PayloadJson, src.PrimaryKeyJson, src.SyncModifiedAt FROM (';

        SET @sql += N'
            SELECT i.' + QUOTENAME(@pk) + N',
                Operation = ' + @opCase + N',
                PayloadJson = (SELECT ' + @jsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                PrimaryKeyJson = (SELECT i.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
            FROM inserted i LEFT JOIN deleted d ON d.' + QUOTENAME(@pk) + N' = i.' + QUOTENAME(@pk);

        IF @isDetail = 1
            SET @sql += N'
            UNION ALL
            SELECT d.' + QUOTENAME(@pk) + N', Operation = ''D'',
                PayloadJson = (SELECT ' + @delJsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                PrimaryKeyJson = (SELECT d.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                SyncModifiedAt = sysutcdatetime()
            FROM deleted d WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.' + QUOTENAME(@pk) + N' = d.' + QUOTENAME(@pk) + N')';

        SET @sql += N'
        ) src
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT ''L2C'', N''' + @TableName + N''', c.PrimaryKeyJson, c.Operation, c.PayloadJson, c.SyncModifiedAt
    FROM changed c
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.SyncOutbox o
        WHERE o.Direction = ''L2C'' AND o.TableName = N''' + @TableName + N'''
          AND o.PrimaryKeyJson = c.PrimaryKeyJson AND o.Status = ''Pending''
          AND o.CreatedAt > DATEADD(second, -1, sysutcdatetime())
    );
END';
        EXEC sp_executesql @sql;

        -- Block physical delete on head/master tables with soft delete
        IF @isDetail = 0 AND (@hasDeleted = 1 OR COL_LENGTH(@TableName, 'IsDeleted') IS NOT NULL)
        BEGIN
            IF OBJECT_ID(N'dbo.tr_SyncBlockDelete_' + @TableName, N'TR') IS NOT NULL
                EXEC(N'DROP TRIGGER dbo.tr_SyncBlockDelete_' + @TableName);

            SET @sql = N'CREATE TRIGGER dbo.tr_SyncBlockDelete_' + @TableName + N'
ON ' + QUOTENAME(@TableName) + N'
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF SESSION_CONTEXT(N''SyncAllowPhysicalDelete'') = 1 BEGIN
        DELETE t FROM ' + QUOTENAME(@TableName) + N' t INNER JOIN deleted d ON d.' + QUOTENAME(@pk) + N' = t.' + QUOTENAME(@pk) + N';
        RETURN;
    END
    RAISERROR(N''Physical DELETE blocked on ' + @TableName + N'. Use soft delete (Deleted=1).'', 16, 1);
END';
            EXEC sp_executesql @sql;
        END
    END

    MERGE dbo.SyncConfig AS t
    USING (SELECT
        @TableName AS TableName,
        CAST(1 AS bit) AS IsEnabled,
        CAST(CASE WHEN @InstallCapture = 1 THEN 1 ELSE 0 END AS bit) AS CaptureLocal,
        CAST(0 AS bit) AS CaptureCloud,
        @pk AS PrimaryKeyColumns,
        CAST(100 AS int) AS BatchSize,
        @Priority AS Priority,
        N'Auto-installed by SyncInstall_Table' AS Notes
    ) AS s
    ON t.TableName = s.TableName
    WHEN MATCHED THEN UPDATE SET
        IsEnabled = 1,
        PrimaryKeyColumns = s.PrimaryKeyColumns,
        Priority = s.Priority,
        CaptureLocal = CASE WHEN @InstallCapture = 1 THEN 1 ELSE t.CaptureLocal END,
        Notes = COALESCE(t.Notes, s.Notes)
    WHEN NOT MATCHED THEN
        INSERT (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
        VALUES (s.TableName, s.IsEnabled, s.CaptureLocal, s.CaptureCloud, s.PrimaryKeyColumns, s.BatchSize, s.Priority, s.Notes);
END
GO

/*
  Run install for all eligible tables.

  SSMS (Local): run DataSync_11_RunLocal.sql
  SSMS (Cloud): run DataSync_11_RunCloud.sql
  sqlcmd:       sqlcmd -v InstallCapture=1 -i DataSync_11_RunInstall.sql
*/

PRINT 'SyncInstall_Table procedure ready.';
PRINT 'Next: run DataSync_11_RunLocal.sql on Local (or Deploy-EnableAllTables.cmd).';
GO
