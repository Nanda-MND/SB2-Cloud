/*
  CLOUD — Purchase C2L: Conflict + Synced-but-missing → Pending again.

  From screenshots:
    Cloud: AttemptCount=1, mix of Synced + Conflict
    Local SB1: only ID 2000000000, 2000000001 (missing 2000000002+)

  Agent IS pulling. Synced without Local row = apply to wrong Local DB
  OR LocalWins Conflict then older Synced noise OR Soft-delete EXISTS check.

  Run AFTER Local:
    Fix_PurchaseC2L_LocalWinsUnblock.sql
    DataSync_10_SyncApply_Generic.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== ' + DB_NAME() + N' — requeue Purchase C2L (CLOUD) ===';
IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'CLOUD only.', 16, 1);
    RETURN;
END
GO

PRINT N'=== BEFORE ===';
SELECT Status, COUNT(*) Cnt,
       SUM(CASE WHEN AttemptCount = 0 THEN 1 ELSE 0 END) Attempt0
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Status;

SELECT TOP 15 OutboxID, TableName, Status, AttemptCount, PrimaryKeyJson,
       LEFT(ISNULL(LastError, N''), 100) Err
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY OutboxID DESC;
GO

-- Bump Cloud row clocks so LocalWins cannot win on timestamp
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;

UPDATE dbo.PurchaseHead
SET SyncModifiedAt = SYSUTCDATETIME(), SyncOrigin = 2
WHERE ID >= 2000000000;
PRINT N'Head SyncModifiedAt bumped: ' + CAST(@@ROWCOUNT AS nvarchar(20));

UPDATE dbo.PurchaseDetail
SET SyncModifiedAt = SYSUTCDATETIME(), SyncOrigin = 2
WHERE ID >= 2000000000 OR RefID >= 2000000000;
PRINT N'Detail SyncModifiedAt bumped: ' + CAST(@@ROWCOUNT AS nvarchar(20));

BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
GO

-- Requeue ALL recent Purchase C2L (Conflict + Synced + Syncing + DeadLetter)
UPDATE dbo.SyncOutbox
SET Status = N'Pending',
    AttemptCount = 0,
    LastError = NULL,
    SyncedAt = NULL,
    SyncModifiedAt = SYSUTCDATETIME()
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status IN (N'Conflict', N'Synced', N'Syncing', N'DeadLetter')
  AND CreatedAt >= DATEADD(day, -60, SYSUTCDATETIME())
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');

PRINT N'Requeued to Pending: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

-- Fresh payloads for Head/Detail (overwrite Pending with current row JSON)
DECLARE @tbl sysname, @pk sysname, @filter nvarchar(500), @jsonCols nvarchar(max), @sql nvarchar(max);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
SELECT * FROM (VALUES
    (N'PurchaseHead',   N'ID', N't.ID >= 2000000000'),
    (N'PurchaseDetail', N'ID', N't.ID >= 2000000000 OR t.RefID >= 2000000000')
) v(TableName, Pk, FilterSql);

OPEN c;
FETCH NEXT FROM c INTO @tbl, @pk, @filter;
WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM dbo.SyncOutbox
    WHERE Direction = N'C2L' AND TableName = @tbl AND Status = N'Pending'
      AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');

    SET @jsonCols = NULL;
    SELECT @jsonCols = STRING_AGG(
        CASE
            WHEN c.name = N'IsDeleted' THEN N'IsDeleted = ISNULL(t.IsDeleted, 0)'
            WHEN c.name = N'Deleted' THEN N'Deleted = ISNULL(t.Deleted, 0)'
            ELSE N't.' + QUOTENAME(c.name)
        END, N', ')
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(N'dbo.' + @tbl)
      AND c.is_computed = 0 AND c.system_type_id NOT IN (34, 35, 99, 189);

    SET @sql = N'
INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
SELECT N''C2L'', @tbl,
    (SELECT t.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    N''U'',
    (SELECT ' + @jsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    t.SyncModifiedAt
FROM dbo.' + QUOTENAME(@tbl) + N' t
WHERE (' + @filter + N');';
    EXEC sp_executesql @sql, N'@tbl sysname', @tbl = @tbl;
    PRINT N'Fresh Pending ' + @tbl + N': ' + CAST(@@ROWCOUNT AS nvarchar(20));

    FETCH NEXT FROM c INTO @tbl, @pk, @filter;
END
CLOSE c; DEALLOCATE c;
GO

PRINT N'=== AFTER (expect Pending > 0) ===';
SELECT Status, COUNT(*) Cnt FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Status;

SELECT TOP 20 OutboxID, TableName, Status, AttemptCount, PrimaryKeyJson, SyncModifiedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status = N'Pending'
ORDER BY CASE TableName WHEN N'PurchaseHead' THEN 0 ELSE 1 END, OutboxID;

PRINT N'';
PRINT N'1) LOCAL must already have run DataSync_10 + Step3a_Local_PurchaseC2L_Prep.sql.';
PRINT N'2) Keep SyncAgent running (restart if idle).';
PRINT N'3) LOCAL: SELECT ID FROM PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;';
PRINT N'4) If still only 2000000000/1 after Synced: Agent Local DB != SB1 (DBConnection.ini).';
GO
