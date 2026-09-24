/*
  ============================================================================
  LOCAL ONLY — force L2C Op=D for PurchaseDetail rows deleted locally
                but still present on Cloud (e.g. remark='test' ID 20384/20385)
  ============================================================================
  Case: documentID oa021565 / RefID 2000000006
    Local has detail 2000000012, 2000000013 only
    Cloud still has 20384, 20385 (remark=test) + the two cloud lines

  Also reinstalls DELETE capture via DataSync_06 reminder.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== LOCAL force PurchaseDetail Op=D L2C ===';
PRINT N'DB=' + DB_NAME();

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%' OR DB_NAME() LIKE N'%abb%'
BEGIN
    RAISERROR(N'STOP: Cloud DB. Run on LOCAL SB1 only.', 16, 1);
    RETURN;
END
GO

/* ---- A) Confirm Local no longer has the deleted lines ---- */
PRINT N'--- A) Local details for RefID 2000000006 ---';
SELECT d.ID, d.RefID, d.Sr, d.Remark, d.IsDeleted
FROM dbo.PurchaseDetail d
WHERE d.RefID = 2000000006
ORDER BY d.ID;
GO

/* ---- B) Outbox history for the deleted Local IDs ---- */
PRINT N'--- B) Outbox for 20384 / 20385 ---';
SELECT TOP 30 OutboxID, Operation, Status, AttemptCount, PrimaryKeyJson,
       LEFT(ISNULL(LastError,N''), 100) Err, CreatedAt, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName = N'PurchaseDetail'
  AND (PrimaryKeyJson LIKE N'%"ID":20384%' OR PrimaryKeyJson LIKE N'%"ID":20385%'
       OR PrimaryKeyJson LIKE N'%20384%' OR PrimaryKeyJson LIKE N'%20385%')
ORDER BY OutboxID DESC;
GO

/* ---- C) Force enqueue Op=D (even if row already gone locally) ---- */
PRINT N'--- C) Insert Pending L2C Op=D ---';

DECLARE @ids TABLE (ID bigint PRIMARY KEY);
INSERT INTO @ids (ID) VALUES (20384), (20385);

-- Cancel stuck Pending U/I for same keys so Op=D is not blocked by dedupe
UPDATE dbo.SyncOutbox
SET Status = N'Synced',
    LastError = N'Superseded by forced Op=D',
    SyncedAt = SYSUTCDATETIME()
WHERE Direction = N'L2C'
  AND TableName = N'PurchaseDetail'
  AND Status IN (N'Pending', N'Syncing')
  AND (PrimaryKeyJson LIKE N'%"ID":20384%' OR PrimaryKeyJson LIKE N'%"ID":20385%'
       OR PrimaryKeyJson LIKE N'%20384%' OR PrimaryKeyJson LIKE N'%20385%');
PRINT N'Superseded Pending: ' + CAST(@@ROWCOUNT AS nvarchar(20));

INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
SELECT
    N'L2C',
    N'PurchaseDetail',
    (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    N'D',
    (SELECT i.ID AS ID, RefID = 2000000006, Remark = N'test', IsDeleted = CAST(1 AS bit)
     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    SYSUTCDATETIME()
FROM @ids i;
PRINT N'Forced Op=D inserted: ' + CAST(@@ROWCOUNT AS nvarchar(20));

SELECT TOP 10 OutboxID, Operation, Status, AttemptCount, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C' AND TableName = N'PurchaseDetail' AND Operation = N'D'
ORDER BY OutboxID DESC;
GO

/* ---- D) Trigger must capture future DELETE ---- */
PRINT N'--- D) DELETE capture check ---';
SELECT tr.name,
       CASE WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%DELETE%'
             AND OBJECT_DEFINITION(tr.object_id) LIKE N'%''D''%'
            THEN N'OK_DELETE_CAPTURE' ELSE N'BAD_REINSTALL_DataSync_06' END AS Verdict
FROM sys.triggers tr
WHERE OBJECT_NAME(tr.parent_id) = N'PurchaseDetail'
  AND tr.name LIKE N'%SyncOutbox%';
GO

PRINT N'============================================================';
PRINT N'Keep SyncAgent running. Cloud should hard-delete 20384/20385.';
PRINT N'If trigger Verdict=BAD → run docs/sql/DataSync_06_Purchase.sql on LOCAL.';
PRINT N'Cloud must have DataSync_10 (hardDeleteDetail) + SyncApply_PurchaseDetail @Operation.';
PRINT N'============================================================';
GO
