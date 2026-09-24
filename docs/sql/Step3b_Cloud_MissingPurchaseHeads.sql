/*
  ============================================================================
  STEP 3b — CLOUD: status for Heads 2..4 + force requeue ONLY those missing
  ============================================================================
  After Step3a + Cloud requeue, Local still only has 2000000000/1
  (SyncModifiedAt matched requeue ⇒ Agent writes SB1; INSERT of 2..4 not landed).

  Run on CLOUD (*warehouse). Keep SyncAgent running.
  If still missing after Pending→Synced: Generate_PurchaseC2L_ApplyOnLocal.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'STEP 3b CLOUD — missing PurchaseHeads 2000000002..4';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME;
PRINT N'============================================================';

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'STOP: LOCAL DB. Run on CLOUD warehouse only.', 16, 1);
    RETURN;
END
GO

PRINT N'--- A) Cloud Heads 0..4 ---';
SELECT ID, SyncOrigin, SyncModifiedAt, ISNULL(Deleted, 0) AS Deleted
FROM dbo.PurchaseHead
WHERE ID BETWEEN 2000000000 AND 2000000004
ORDER BY ID;
GO

PRINT N'--- B) Latest C2L outbox per Head 0..4 ---';
;WITH want AS (
    SELECT v.ID
    FROM (VALUES
        (CAST(2000000000 AS bigint)),(2000000001),(2000000002),(2000000003),(2000000004)
    ) v(ID)
),
ranked AS (
    SELECT
        o.OutboxID, o.Status, o.AttemptCount, o.PrimaryKeyJson,
        o.SyncModifiedAt, o.SyncedAt,
        LEFT(ISNULL(o.LastError, N''), 200) AS LastError,
        TRY_CAST(JSON_VALUE(o.PrimaryKeyJson, N'$.ID') AS bigint) AS HeadId,
        ROW_NUMBER() OVER (
            PARTITION BY TRY_CAST(JSON_VALUE(o.PrimaryKeyJson, N'$.ID') AS bigint)
            ORDER BY o.OutboxID DESC
        ) AS rn
    FROM dbo.SyncOutbox o
    WHERE o.Direction = N'C2L'
      AND o.TableName = N'PurchaseHead'
      AND TRY_CAST(JSON_VALUE(o.PrimaryKeyJson, N'$.ID') AS bigint)
          BETWEEN 2000000000 AND 2000000004
)
SELECT w.ID AS HeadId,
       r.Status, r.AttemptCount, r.OutboxID, r.SyncModifiedAt, r.SyncedAt, r.LastError
FROM want w
LEFT JOIN ranked r ON r.HeadId = w.ID AND r.rn = 1
ORDER BY w.ID;
GO

PRINT N'--- C) Detail C2L status (cloud-zone) ---';
SELECT Status, COUNT(*) Cnt,
       SUM(CASE WHEN AttemptCount = 0 THEN 1 ELSE 0 END) Attempt0
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName = N'PurchaseDetail'
  AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":2%')
GROUP BY Status;
GO

PRINT N'--- D) Force requeue ONLY Heads/Details 2..4 ---';
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;

UPDATE dbo.PurchaseHead
SET SyncModifiedAt = SYSUTCDATETIME(), SyncOrigin = 2
WHERE ID IN (2000000002, 2000000003, 2000000004);
PRINT N'Head clock bump 2..4: ' + CAST(@@ROWCOUNT AS nvarchar(20));

UPDATE dbo.PurchaseDetail
SET SyncModifiedAt = SYSUTCDATETIME(), SyncOrigin = 2
WHERE RefID IN (2000000002, 2000000003, 2000000004)
   OR ID IN (2000000002, 2000000003, 2000000004);
PRINT N'Detail clock bump 2..4: ' + CAST(@@ROWCOUNT AS nvarchar(20));

BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;

DELETE FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (
        PrimaryKeyJson LIKE N'%2000000002%'
     OR PrimaryKeyJson LIKE N'%2000000003%'
     OR PrimaryKeyJson LIKE N'%2000000004%'
      );
PRINT N'Old outbox rows removed: ' + CAST(@@ROWCOUNT AS nvarchar(20));

DECLARE @tbl sysname, @pk sysname, @filter nvarchar(500), @jsonCols nvarchar(max), @sql nvarchar(max);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
SELECT * FROM (VALUES
    (N'PurchaseHead',   N'ID', N't.ID IN (2000000002,2000000003,2000000004)'),
    (N'PurchaseDetail', N'ID', N't.RefID IN (2000000002,2000000003,2000000004)')
) v(TableName, Pk, FilterSql);

OPEN c;
FETCH NEXT FROM c INTO @tbl, @pk, @filter;
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
      AND c.is_computed = 0 AND c.system_type_id NOT IN (34, 35, 99, 189);

    SET @sql = N'
INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
SELECT N''C2L'', @tbl,
    (SELECT t.' + QUOTENAME(@pk) + N' AS ' + QUOTENAME(@pk) + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    N''I'',
    (SELECT ' + @jsonCols + N' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    t.SyncModifiedAt
FROM dbo.' + QUOTENAME(@tbl) + N' t
WHERE (' + @filter + N');';
    EXEC sp_executesql @sql, N'@tbl sysname', @tbl = @tbl;
    PRINT N'Fresh Pending I ' + @tbl + N': ' + CAST(@@ROWCOUNT AS nvarchar(20));

    FETCH NEXT FROM c INTO @tbl, @pk, @filter;
END
CLOSE c; DEALLOCATE c;
GO

PRINT N'--- E) AFTER Pending for 2..4 ---';
SELECT OutboxID, TableName, Status, AttemptCount, PrimaryKeyJson, Operation, SyncModifiedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND Status = N'Pending'
  AND (
        PrimaryKeyJson LIKE N'%2000000002%'
     OR PrimaryKeyJson LIKE N'%2000000003%'
     OR PrimaryKeyJson LIKE N'%2000000004%'
      )
ORDER BY CASE TableName WHEN N'PurchaseHead' THEN 0 ELSE 1 END, OutboxID;
GO

PRINT N'============================================================';
PRINT N'1) Restart SyncAgent if AttemptCount stays 0.';
PRINT N'2) Wait Status=Synced (or Conflict + LastError).';
PRINT N'3) LOCAL: SELECT ID FROM PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;';
PRINT N'4) Synced on Cloud but still missing Local → Generate_PurchaseC2L_ApplyOnLocal.sql';
PRINT N'============================================================';
GO
