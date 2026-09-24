/*
  CLOUD — why NEW Purchase IDs (e.g. 2000000002+) never reach Local.

  Soft-delete / LocalWins only affects IDs that ALREADY exist on Local.
  New cloud-zone IDs missing on Local = capture / outbox / Agent problem.

  Run on CLOUD (db_abbe78_warehouse).
*/

SET NOCOUNT ON;

PRINT N'=== DB: ' + DB_NAME() + N' ===';

PRINT N'=== 1) Cloud PurchaseHead cloud-zone (expect 2000000002+ here) ===';
SELECT ID, Date, AutoID, ISNULL(Deleted,0) AS Deleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID DESC;

PRINT N'=== 2) SyncConfig (MUST CaptureCloud=1, CaptureLocal=0, IsEnabled=1) ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');

PRINT N'=== 3) Triggers on Purchase (need C2L capture, NOT L2C-only) ===';
SELECT tr.name, OBJECT_NAME(tr.parent_id) AS ParentTable, tr.is_disabled,
       CASE
           WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%Direction%C2L%'
                OR OBJECT_DEFINITION(tr.object_id) LIKE N'%''C2L''%'
               THEN N'Writes C2L'
           WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%Direction%L2C%'
                OR OBJECT_DEFINITION(tr.object_id) LIKE N'%''L2C''%'
               THEN N'Writes L2C (WRONG on Cloud)'
           ELSE N'Unknown'
       END AS DirectionHint,
       CASE
           WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%CaptureCloud%1%' THEN N'Checks CaptureCloud'
           WHEN OBJECT_DEFINITION(tr.object_id) LIKE N'%CaptureLocal%1%' THEN N'Checks CaptureLocal (Cloud edits ignored if CaptureLocal=0)'
           ELSE N'?'
       END AS CaptureHint
FROM sys.triggers tr
WHERE OBJECT_NAME(tr.parent_id) IN (N'PurchaseHead', N'PurchaseDetail')
   OR tr.name LIKE N'%Purchase%Sync%'
   OR tr.name LIKE N'tr_SyncOutbox_Purchase%'
ORDER BY ParentTable, tr.name;

PRINT N'=== 4) SyncInstall_CloudCapture present? ===';
SELECT CASE WHEN OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
            THEN N'MISSING — run DataSync_28_EnableC2L_Capture.sql'
            ELSE N'OK' END AS SyncInstall_CloudCapture;

PRINT N'=== 5) Outbox by Direction for Purchase (Cloud L2C Pending = Agent never pulls) ===';
SELECT Direction, Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
GROUP BY Direction, Status
ORDER BY Direction, Status;

PRINT N'=== 6) Outbox rows for each cloud-zone Head ID ===';
;WITH ids AS (
    SELECT ID FROM dbo.PurchaseHead WHERE ID >= 2000000000
)
SELECT i.ID,
       SUM(CASE WHEN o.Direction = N'C2L' AND o.Status = N'Pending' THEN 1 ELSE 0 END) AS C2L_Pending,
       SUM(CASE WHEN o.Direction = N'C2L' AND o.Status = N'Synced' THEN 1 ELSE 0 END) AS C2L_Synced,
       SUM(CASE WHEN o.Direction = N'C2L' AND o.Status = N'Conflict' THEN 1 ELSE 0 END) AS C2L_Conflict,
       SUM(CASE WHEN o.Direction = N'L2C' THEN 1 ELSE 0 END) AS L2C_Any,
       MAX(o.OutboxID) AS MaxOutboxID
FROM ids i
LEFT JOIN dbo.SyncOutbox o
  ON o.TableName IN (N'PurchaseHead', N'PurchaseDetail')
 AND (
        o.PrimaryKeyJson LIKE N'%"ID":' + CAST(i.ID AS nvarchar(20)) + N'%'
     OR o.PrimaryKeyJson LIKE N'%"ID": ' + CAST(i.ID AS nvarchar(20)) + N'%'
     )
GROUP BY i.ID
ORDER BY i.ID DESC;

PRINT N'=== 7) Recent Purchase outbox (any Direction) ===';
SELECT TOP 40 OutboxID, Direction, TableName, Status, PrimaryKeyJson, AttemptCount,
       CreatedAt, SyncedAt, LEFT(ISNULL(LastError,N''), 120) AS Err
FROM dbo.SyncOutbox
WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail')
ORDER BY OutboxID DESC;

PRINT N'';
PRINT N'Interpretation:';
PRINT N'  - CaptureCloud=0 or no C2L trigger → new Cloud purchases never enqueue.';
PRINT N'  - Trigger checks CaptureLocal + writes L2C → Cloud edits go to L2C; Agent only pulls C2L from Cloud.';
PRINT N'  - C2L_Pending=0 and C2L_Synced=0 for an ID → never captured; run Fix_PurchaseC2L_CloudForceEnqueue.sql';
PRINT N'  - C2L_Synced>0 but Local missing → Agent marked Synced without land; force enqueue + Local SyncApply NEW_OK.';
GO
