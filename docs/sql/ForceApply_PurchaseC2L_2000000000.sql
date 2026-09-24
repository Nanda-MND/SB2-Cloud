/*
  Force C2L Purchase 2000000000 onto LOCAL when Cloud outbox is Synced but Local empty.

  STEP A — run on CLOUD (copy PayloadJson results)
  STEP B — run on LOCAL (paste payloads into variables, then EXEC apply)

  Local CaptureCloud=0 is correct; do not change it.
*/

/* ===================== A) CLOUD ===================== */
SET NOCOUNT ON;
PRINT '=== CLOUD: latest payloads for ID 2000000000 ===';

SELECT TOP 1 OutboxID, TableName, Status, LEN(PayloadJson) AS PayloadLen,
       LEFT(PayloadJson, 200) AS PayloadPreview, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName = N'PurchaseHead'
  AND PrimaryKeyJson LIKE N'%2000000000%'
ORDER BY OutboxID DESC;

SELECT TOP 1 OutboxID, TableName, Status, LEN(PayloadJson) AS PayloadLen,
       LEFT(PayloadJson, 200) AS PayloadPreview, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName = N'PurchaseDetail'
  AND PrimaryKeyJson LIKE N'%2000000000%'
ORDER BY OutboxID DESC;

-- Re-queue for Agent (optional, after Local force-apply test)
-- UPDATE dbo.SyncOutbox SET Status=N'Pending', AttemptCount=0, LastError=NULL, SyncedAt=NULL
-- WHERE Direction=N'C2L' AND TableName IN (N'PurchaseHead',N'PurchaseDetail')
--   AND PrimaryKeyJson LIKE N'%2000000000%';
GO

/* ===================== B) LOCAL — paste payloads from Cloud =====================
   1) Cloud query: SELECT TOP 1 PayloadJson FROM SyncOutbox WHERE ... PurchaseHead ...
   2) Paste into @HeadJson / @DetailJson below
   3) Execute on SB1
*/

/*
SET NOCOUNT ON;

DECLARE @HeadJson nvarchar(max) = N'PASTE_PURCHASEHEAD_PAYLOAD_HERE';
DECLARE @DetailJson nvarchar(max) = N'PASTE_PURCHASEDETAIL_PAYLOAD_HERE';
DECLARE @Conflict bit, @Applied bit;

BEGIN TRY
    EXEC dbo.SyncApply_Generic
        @Source = N'Cloud',
        @TableName = N'PurchaseHead',
        @PayloadJson = @HeadJson,
        @PrimaryKeyJson = N'{"ID":2000000000}',
        @RemoteModifiedAt = SYSUTCDATETIME(),
        @Operation = N'U',
        @OutboxID = NULL,
        @ConflictLogged = @Conflict OUTPUT,
        @Applied = @Applied OUTPUT;
    PRINT 'Head Applied=' + CAST(@Applied AS nvarchar(5)) + N' Conflict=' + CAST(@Conflict AS nvarchar(5));
END TRY
BEGIN CATCH
    PRINT 'Head FAIL: ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    SET @Conflict = 0; SET @Applied = 0;
    EXEC dbo.SyncApply_Generic
        @Source = N'Cloud',
        @TableName = N'PurchaseDetail',
        @PayloadJson = @DetailJson,
        @PrimaryKeyJson = N'{"ID":2000000000}',
        @RemoteModifiedAt = SYSUTCDATETIME(),
        @Operation = N'U',
        @OutboxID = NULL,
        @ConflictLogged = @Conflict OUTPUT,
        @Applied = @Applied OUTPUT;
    PRINT 'Detail Applied=' + CAST(@Applied AS nvarchar(5)) + N' Conflict=' + CAST(@Conflict AS nvarchar(5));
END TRY
BEGIN CATCH
    PRINT 'Detail FAIL: ' + ERROR_MESSAGE();
END CATCH

SELECT ID, Remark FROM dbo.PurchaseHead WHERE ID = 2000000000;
SELECT ID, RefID, CodeID, Qty FROM dbo.PurchaseDetail WHERE RefID = 2000000000;
*/
GO
