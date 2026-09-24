/*
  ============================================================================
  LOCAL ONLY — force L2C Op=D for TransferDetail lines deleted locally
                but still on Cloud (AutoID H260900013 / RefID 2000000015)
  ============================================================================
  Local: only detail 2000000087 remains
  Cloud: still has 64191, 64276 (Remark='test') + 2000000087
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== LOCAL force TransferDetail Op=D L2C ===';
PRINT N'DB=' + DB_NAME();

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%abbe%' OR DB_NAME() LIKE N'%abb%'
BEGIN
    RAISERROR(N'STOP: Cloud DB. Run on LOCAL SB1 only.', 16, 1);
    RETURN;
END
GO

PRINT N'--- A) Local details for RefID 2000000015 ---';
SELECT d.ID, d.RefID, d.Sr, d.Remark, d.IsDeleted
FROM dbo.TransferDetail d
WHERE d.RefID = 2000000015
ORDER BY d.ID;
GO

PRINT N'--- B) Outbox history for 64191 / 64276 ---';
SELECT TOP 40 OutboxID, Operation, Status, AttemptCount, PrimaryKeyJson,
       LEFT(ISNULL(LastError,N''), 100) Err, CreatedAt, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
  AND TableName = N'TransferDetail'
  AND (PrimaryKeyJson LIKE N'%64191%' OR PrimaryKeyJson LIKE N'%64276%')
ORDER BY OutboxID DESC;
GO

PRINT N'--- C) Force Pending L2C Op=D ---';
DECLARE @ids TABLE (ID bigint PRIMARY KEY);
INSERT INTO @ids (ID) VALUES (64191), (64276);

UPDATE dbo.SyncOutbox
SET Status = N'Synced',
    LastError = N'Superseded by forced TransferDetail Op=D',
    SyncedAt = SYSUTCDATETIME()
WHERE Direction = N'L2C'
  AND TableName = N'TransferDetail'
  AND Status IN (N'Pending', N'Syncing')
  AND (PrimaryKeyJson LIKE N'%64191%' OR PrimaryKeyJson LIKE N'%64276%');
PRINT N'Superseded Pending: ' + CAST(@@ROWCOUNT AS nvarchar(20));

INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
SELECT
    N'L2C',
    N'TransferDetail',
    (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    N'D',
    (SELECT i.ID AS ID, RefID = CAST(2000000015 AS bigint), Remark = N'test', IsDeleted = CAST(1 AS bit)
     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
    SYSUTCDATETIME()
FROM @ids i;
PRINT N'Forced Op=D inserted: ' + CAST(@@ROWCOUNT AS nvarchar(20));

SELECT TOP 10 OutboxID, Operation, Status, AttemptCount, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C' AND TableName = N'TransferDetail' AND Operation = N'D'
ORDER BY OutboxID DESC;
GO

PRINT N'--- D) DELETE capture on TransferDetail ---';
SELECT tr.name,
       CASE WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%DELETE%'
             AND OBJECT_DEFINITION(tr.object_id) LIKE N'%''D''%'
            THEN N'OK_DELETE_CAPTURE' ELSE N'BAD — run Fix_Transfer_Local_L2C_Capture.sql' END AS Verdict
FROM sys.triggers tr
WHERE OBJECT_NAME(tr.parent_id) = N'TransferDetail'
  AND tr.name LIKE N'%SyncOutbox%';
GO

PRINT N'Keep SyncAgent running. Then Cloud: Fix_Cloud_HardDelete_TransferDetail_64191_64276.sql';
PRINT N'Also ensure DataSync_10 (hardDeleteDetail) + SyncApply_TransferDetail @Operation on Cloud.';
GO
