/*
  CLOUD ONLY — fix stale SyncModifiedAt that causes LocalWins on C2L.

  Yes: if Cloud SyncModifiedAt is OLDER than Local, Agent skips apply
  (LocalWinsSkipped / Conflict).

  Aug 22 timestamps usually mean LocalWinsUnblock (DATEADD -30 days) was
  run on the WRONG side (Cloud). Local should be aged; Cloud must be NOW.

  This script:
    1) Sets SyncModifiedAt = SYSUTCDATETIME() on cloud-zone Purchase Head/Detail
    2) Resets C2L outbox → Pending
    3) Re-inserts C2L payloads so PayloadJson + SyncModifiedAt are fresh
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== ' + DB_NAME() + N' — bump Purchase SyncModifiedAt (CLOUD) ===';

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'Refused: CLOUD only. On Local, Aug 22 after LocalWinsUnblock is intentional.', 16, 1);
    RETURN;
END
GO

PRINT N'=== BEFORE ===';
SELECT ID, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;

SELECT Status, COUNT(*) AS Cnt,
       MIN(SyncModifiedAt) AS MinOutboxMod,
       MAX(SyncModifiedAt) AS MaxOutboxMod
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Status;
GO

PRINT N'=== 1) Stamp SyncModifiedAt = NOW on Cloud Purchase (suppress outbox) ===';
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;

UPDATE dbo.PurchaseHead
SET SyncModifiedAt = SYSUTCDATETIME(),
    SyncOrigin = 2
WHERE ID >= 2000000000;
PRINT N'PurchaseHead bumped: ' + CAST(@@ROWCOUNT AS nvarchar(20));

UPDATE dbo.PurchaseDetail
SET SyncModifiedAt = SYSUTCDATETIME(),
    SyncOrigin = 2
WHERE ID >= 2000000000 OR RefID >= 2000000000;
PRINT N'PurchaseDetail bumped: ' + CAST(@@ROWCOUNT AS nvarchar(20));

BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
GO

PRINT N'=== 2) Reset existing C2L outbox → Pending (will re-payload next) ===';
UPDATE dbo.SyncOutbox
SET Status = N'Pending',
    AttemptCount = 0,
    LastError = NULL,
    SyncedAt = NULL,
    SyncModifiedAt = SYSUTCDATETIME()
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%');
PRINT N'Outbox SyncModifiedAt bumped / Pending: ' + CAST(@@ROWCOUNT AS nvarchar(20));
GO

PRINT N'=== 3) Re-insert fresh C2L payloads (Head then Detail) ===';
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
    -- Drop old Pending for this table so fresh payload wins
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
      AND c.is_computed = 0
      AND c.system_type_id NOT IN (34, 35, 99, 189);

    IF @jsonCols IS NOT NULL
    BEGIN
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
        PRINT N'Fresh C2L ' + @tbl + N': ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END
    FETCH NEXT FROM tables INTO @tbl, @pk, @filter;
END
CLOSE tables; DEALLOCATE tables;
GO

PRINT N'=== AFTER (SyncModifiedAt must be ~ now, not Aug 22) ===';
SELECT ID, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;

SELECT TOP 15 OutboxID, TableName, Status, SyncModifiedAt, PrimaryKeyJson
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY OutboxID DESC;

PRINT N'Restart SyncAgent. Local should accept because Cloud ModAt is newer.';
PRINT N'LOCAL verify: SELECT ID, SyncModifiedAt FROM PurchaseHead WHERE ID >= 2000000000;';
GO
