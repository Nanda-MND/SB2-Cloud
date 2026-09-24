/*
  CLOUD ONLY — Purchase C2L force enqueue (self-contained).

  If you ran an older Cloud script on LOCAL by mistake, first repair Local:
    Fix_PurchaseC2L_LocalAfterWrongCloudRun.sql

  Run order:
    1) LOCAL: Fix_PurchaseC2L_LocalAfterWrongCloudRun.sql (if Cloud script was run on Local)
    2) LOCAL: Fix_PurchaseC2L_LocalWinsUnblock.sql
    3) LOCAL: DataSync_10_SyncApply_Generic.sql
    4) CLOUD: THIS file  (must be db_*warehouse / site4now — NOT SB1)
    5) SyncAgent running
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== ' + DB_NAME() + N' — Purchase C2L force enqueue (CLOUD) ===';

IF DB_NAME() IN (N'SB1', N'SB') OR DB_NAME() NOT LIKE N'%abbe%' AND DB_NAME() NOT LIKE N'%warehouse%'
BEGIN
    PRINT N'WARN: DB name does not look like Cloud warehouse. Abort if this is Local SB1.';
END

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'Refused: this is Local SB. Use Fix_PurchaseC2L_LocalAfterWrongCloudRun.sql on Local.', 16, 1);
    RETURN;
END
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

PRINT N'=== B) SyncConfig + install Purchase C2L triggers ===';
MERGE dbo.SyncConfig AS t
USING (VALUES
    (N'PurchaseHead',   1, 0, 1, N'ID',  50, 40, N'Purchase C2L'),
    (N'PurchaseDetail', 1, 0, 1, N'ID', 100, 45, N'Purchase C2L')
) AS s(TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
ON t.TableName = s.TableName
WHEN MATCHED THEN UPDATE SET
    IsEnabled = 1, CaptureLocal = 0, CaptureCloud = 1,
    Notes = LEFT(CONCAT(ISNULL(t.Notes, N''), N' | force ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)), 500)
WHEN NOT MATCHED THEN INSERT
    (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
VALUES
    (s.TableName, s.IsEnabled, s.CaptureLocal, s.CaptureCloud,
     s.PrimaryKeyColumns, s.BatchSize, s.Priority, s.Notes);

EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseHead';
EXEC dbo.SyncInstall_CloudCapture @TableName = N'PurchaseDetail';

SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

SELECT tr.name, OBJECT_NAME(tr.parent_id) AS ParentTable, tr.is_disabled
FROM sys.triggers tr
WHERE OBJECT_NAME(tr.parent_id) IN (N'PurchaseHead', N'PurchaseDetail')
  AND tr.name LIKE N'tr_SyncOutbox_%';
GO

PRINT N'=== C) Cloud-zone PurchaseHead on Cloud ===';
SELECT ID, Date, AutoID, ISNULL(Deleted,0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID;

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseHead WHERE ID >= 2000000002)
    PRINT N'WARN: No ID >= 2000000002 on Cloud.';
GO

PRINT N'=== D) Stamp SyncOrigin=2 ===';
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;

UPDATE dbo.PurchaseHead SET SyncOrigin = 2
WHERE ID >= 2000000000 AND ISNULL(SyncOrigin, 1) <> 2;
PRINT N'Head stamped: ' + CAST(@@ROWCOUNT AS nvarchar(20));

UPDATE dbo.PurchaseDetail SET SyncOrigin = 2
WHERE (ID >= 2000000000 OR RefID >= 2000000000) AND ISNULL(SyncOrigin, 1) <> 2;
PRINT N'Detail stamped: ' + CAST(@@ROWCOUNT AS nvarchar(20));

BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
GO

PRINT N'=== E) Reset + insert C2L Pending ===';
UPDATE dbo.SyncOutbox
SET Status = N'Synced', LastError = N'Cancelled: Cloud Purchase must use C2L', SyncedAt = SYSUTCDATETIME()
WHERE Direction = N'L2C' AND Status IN (N'Pending', N'Syncing')
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%"ID":2%' OR PrimaryKeyJson LIKE N'%200000000%');
PRINT N'Bogus L2C cancelled: ' + CAST(@@ROWCOUNT AS nvarchar(20));

UPDATE dbo.SyncOutbox
SET Status = N'Pending', AttemptCount = 0, LastError = NULL, SyncedAt = NULL
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status IN (N'Syncing', N'Conflict', N'DeadLetter', N'Synced')
  AND CreatedAt >= DATEADD(day, -60, SYSUTCDATETIME())
  AND (PrimaryKeyJson LIKE N'%"ID":2%' OR PrimaryKeyJson LIKE N'%200000000%');
PRINT N'Reset to Pending: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

DECLARE @tbl sysname, @pk sysname, @filter nvarchar(500), @jsonCols nvarchar(max), @sql nvarchar(max);

DECLARE tables CURSOR LOCAL FAST_FORWARD FOR
    SELECT v.TableName, v.Pk, v.FilterSql FROM (VALUES
        (N'PurchaseHead',   N'ID', N't.ID >= 2000000000'),
        (N'PurchaseDetail', N'ID', N't.ID >= 2000000000 OR t.RefID >= 2000000000')
    ) v(TableName, Pk, FilterSql);

OPEN tables;
FETCH NEXT FROM tables INTO @tbl, @pk, @filter;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @jsonCols = NULL;
    SELECT @jsonCols = STRING_AGG(
        CASE
            WHEN c.name = N'IsDeleted' THEN N'IsDeleted = ISNULL(t.IsDeleted, 0)'
            WHEN c.name = N'Deleted' THEN N'Deleted = ISNULL(t.Deleted, 0)'
            ELSE N't.' + QUOTENAME(c.name)
        END, N', ')
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(N'dbo.' + @tbl)
      AND c.is_computed = 0
      AND c.system_type_id NOT IN (34, 35, 99, 189);

    IF @jsonCols IS NOT NULL
    BEGIN
        SET @sql = N'
INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
SELECT N''C2L'', @tbl,
    (SELECT t.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    N''I'',
    (SELECT ' + @jsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    ISNULL(t.SyncModifiedAt, SYSUTCDATETIME())
FROM dbo.' + QUOTENAME(@tbl) + N' t
WHERE (' + @filter + N')
  AND NOT EXISTS (
        SELECT 1 FROM dbo.SyncOutbox o
        WHERE o.Direction = N''C2L'' AND o.TableName = @tbl
          AND o.Status IN (N''Pending'', N''Syncing'')
          AND o.PrimaryKeyJson = (SELECT t2.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N'
                                  FROM dbo.' + QUOTENAME(@tbl) + N' t2
                                  WHERE t2.' + QUOTENAME(@pk) + N' = t.' + QUOTENAME(@pk) + N'
                                  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
      );';
        EXEC sp_executesql @sql, N'@tbl sysname', @tbl = @tbl;
        PRINT N'Inserted C2L ' + @tbl + N': ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END
    FETCH NEXT FROM tables INTO @tbl, @pk, @filter;
END
CLOSE tables; DEALLOCATE tables;
GO

PRINT N'=== F) RESULT ===';
SELECT Direction, Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Direction, Status ORDER BY Direction, Status;

SELECT TOP 40 OutboxID, TableName, Status, PrimaryKeyJson, AttemptCount,
       LEFT(ISNULL(LastError, N''), 150) AS LastError, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%')
ORDER BY OutboxID DESC;

PRINT N'If Conflict/LocalWins → LOCAL Fix_PurchaseC2L_LocalWinsUnblock.sql then re-run this.';
PRINT N'If Pending stuck AttemptCount=0 → restart SyncAgent.';
PRINT N'LOCAL: SELECT ID FROM PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;';
GO
