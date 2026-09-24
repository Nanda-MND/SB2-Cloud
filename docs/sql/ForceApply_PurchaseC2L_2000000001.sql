/*
  LOCAL SB1 — force-apply Purchase 2000000001 (Cloud has it; Local only has 2000000000).
  SyncApply_Generic must be NEW_OK (contains 'C2L Applied blocked').

  STEP A — CLOUD: copy full PayloadJson (Results → cell → copy, not grid preview)
  STEP B — LOCAL: paste into @HeadJson / @DetailJson, run batch
  STEP C — CLOUD: requeue OutboxID 676862 / 676863 (or PK match) to Pending
*/

/* ===================== A) CLOUD ===================== */
SET NOCOUNT ON;

SELECT OutboxID, TableName, Status, AttemptCount, LastError,
       LEN(PayloadJson) AS PayloadLen, PrimaryKeyJson, SyncedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L'
  AND TableName IN (N'PurchaseHead', N'PurchaseDetail')
  AND (
        OutboxID IN (676862, 676863)
     OR PrimaryKeyJson LIKE N'%2000000001%'
      )
ORDER BY OutboxID;

-- Full payloads (copy each PayloadJson cell):
SELECT TOP 1 OutboxID, PayloadJson
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName = N'PurchaseHead'
  AND PrimaryKeyJson LIKE N'%2000000001%'
ORDER BY OutboxID DESC;

SELECT TOP 1 OutboxID, PayloadJson
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName = N'PurchaseDetail'
  AND PrimaryKeyJson LIKE N'%2000000001%'
ORDER BY OutboxID DESC;
GO

/* ===================== B) LOCAL SB1 — paste payloads, then run ===================== */
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Expect NEW_OK
SELECT CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
    LIKE N'%C2L Applied blocked%' THEN N'NEW_OK' ELSE N'OLD_MISSING_CHECK' END AS SyncApplyVer;

-- Before: only 2000000000 should show until apply succeeds
SELECT ID, SyncOrigin FROM dbo.PurchaseHead WHERE ID >= 2000000000;
SELECT ID, RefID, CodeID, Qty, SyncOrigin FROM dbo.PurchaseDetail WHERE RefID >= 2000000000;

DECLARE @HeadJson nvarchar(max) = NULL;   -- paste Cloud PurchaseHead PayloadJson: N'{...}'
DECLARE @DetailJson nvarchar(max) = NULL; -- paste Cloud PurchaseDetail PayloadJson: N'{...}'
DECLARE @Conflict bit, @Applied bit;
DECLARE @ts datetime2(3) = SYSUTCDATETIME();

IF @HeadJson IS NULL OR LEN(@HeadJson) < 10
BEGIN
    PRINT N'Paste PurchaseHead PayloadJson into @HeadJson first (from Cloud STEP A).';
    RETURN;
END

BEGIN TRY
    SET @Conflict = 0; SET @Applied = 0;
    EXEC dbo.SyncApply_Generic
        @Source = N'Cloud',
        @TableName = N'PurchaseHead',
        @PayloadJson = @HeadJson,
        @PrimaryKeyJson = N'{"ID":2000000001}',
        @RemoteModifiedAt = @ts,
        @Operation = N'I',
        @OutboxID = NULL,
        @ConflictLogged = @Conflict OUTPUT,
        @Applied = @Applied OUTPUT;
    PRINT N'Head Applied=' + CAST(ISNULL(@Applied,0) AS nvarchar(5))
        + N' Conflict=' + CAST(ISNULL(@Conflict,0) AS nvarchar(5));
END TRY
BEGIN CATCH
    PRINT N'Head FAIL: ' + ERROR_MESSAGE();
END CATCH

IF @DetailJson IS NOT NULL AND LEN(@DetailJson) > 10
BEGIN
    BEGIN TRY
        SET @Conflict = 0; SET @Applied = 0;
        EXEC dbo.SyncApply_Generic
            @Source = N'Cloud',
            @TableName = N'PurchaseDetail',
            @PayloadJson = @DetailJson,
            @PrimaryKeyJson = N'{"ID":2000000001}',
            @RemoteModifiedAt = @ts,
            @Operation = N'I',
            @OutboxID = NULL,
            @ConflictLogged = @Conflict OUTPUT,
            @Applied = @Applied OUTPUT;
        PRINT N'Detail Applied=' + CAST(ISNULL(@Applied,0) AS nvarchar(5))
            + N' Conflict=' + CAST(ISNULL(@Conflict,0) AS nvarchar(5));
    END TRY
    BEGIN CATCH
        PRINT N'Detail FAIL: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT N'Skip Detail — paste @DetailJson to apply line.';

SELECT ID, SyncOrigin, AutoID, Remark FROM dbo.PurchaseHead WHERE ID = 2000000001;
SELECT ID, RefID, CodeID, Qty, SyncOrigin FROM dbo.PurchaseDetail WHERE RefID = 2000000001;
GO

/* ===================== C) CLOUD — after Local Head+Detail exist =====================
UPDATE dbo.SyncOutbox
SET Status = N'Pending', AttemptCount = 0, LastError = NULL, SyncedAt = NULL
WHERE Direction = N'C2L'
  AND (
        OutboxID IN (676862, 676863)
     OR (
            TableName IN (N'PurchaseHead', N'PurchaseDetail')
        AND PrimaryKeyJson LIKE N'%2000000001%'
        )
      );

-- Optional: confirm Agent retry leaves Status=Synced AND Local still has rows.
*/
GO
