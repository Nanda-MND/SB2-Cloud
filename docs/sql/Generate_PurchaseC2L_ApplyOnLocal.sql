/*
  CLOUD — generate SyncApply_Generic EXEC batches for Local (Agent bypass).

  Use when:
    - Cloud has Purchase ID >= 2e9
    - Local missing those IDs
    - SyncAgent C2L Pending stuck AttemptCount=0 OR Conflict loop

  How:
    1) Run THIS on CLOUD (Results to Text, or copy Payload grid carefully)
    2) Copy the SqlBatch column values into a new query on LOCAL and execute
    3) LOCAL must already have SyncApply_Generic + SyncConfig IsEnabled=1 for Purchase

  Prefer: fix SyncAgent first. This is a manual lander.
*/

SET NOCOUNT ON;

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'Run on CLOUD only.', 16, 1);
    RETURN;
END

-- Latest C2L payload per TableName + PrimaryKeyJson (prefer Pending/Conflict, else any)
;WITH ranked AS (
    SELECT
        o.OutboxID,
        o.TableName,
        o.PrimaryKeyJson,
        o.Operation,
        o.PayloadJson,
        o.SyncModifiedAt,
        o.Status,
        ROW_NUMBER() OVER (
            PARTITION BY o.TableName, o.PrimaryKeyJson
            ORDER BY
                CASE o.Status
                    WHEN N'Pending' THEN 0
                    WHEN N'Syncing' THEN 1
                    WHEN N'Conflict' THEN 2
                    WHEN N'Synced' THEN 3
                    ELSE 4
                END,
                o.OutboxID DESC
        ) AS rn
    FROM dbo.SyncOutbox o
    WHERE o.Direction = N'C2L'
      AND o.TableName IN (N'PurchaseHead', N'PurchaseDetail')
      AND (
            o.PrimaryKeyJson LIKE N'%"ID":2%'
         OR o.PrimaryKeyJson LIKE N'%200000000%'
          )
      AND o.PayloadJson IS NOT NULL
      AND LEN(o.PayloadJson) > 10
)
SELECT
    TableName,
    PrimaryKeyJson,
    Status AS SourceStatus,
    OutboxID,
    /* Paste each SqlBatch onto LOCAL and run */
    CAST(
        N'DECLARE @c bit=0,@a bit=0;' + NCHAR(13) + NCHAR(10) +
        N'BEGIN TRY' + NCHAR(13) + NCHAR(10) +
        N'  EXEC dbo.SyncApply_Generic' + NCHAR(13) + NCHAR(10) +
        N'    @Source=N''Cloud'',' + NCHAR(13) + NCHAR(10) +
        N'    @TableName=N''' + TableName + N''',' + NCHAR(13) + NCHAR(10) +
        N'    @PayloadJson=N''' + REPLACE(PayloadJson, N'''', N'''''') + N''',' + NCHAR(13) + NCHAR(10) +
        N'    @PrimaryKeyJson=N''' + REPLACE(PrimaryKeyJson, N'''', N'''''') + N''',' + NCHAR(13) + NCHAR(10) +
        N'    @RemoteModifiedAt=SYSUTCDATETIME(),' + NCHAR(13) + NCHAR(10) +
        N'    @Operation=N''' + ISNULL(NULLIF(Operation, N''), N'I') + N''',' + NCHAR(13) + NCHAR(10) +
        N'    @OutboxID=NULL,' + NCHAR(13) + NCHAR(10) +
        N'    @ConflictLogged=@c OUTPUT,' + NCHAR(13) + NCHAR(10) +
        N'    @Applied=@a OUTPUT;' + NCHAR(13) + NCHAR(10) +
        N'  PRINT N''' + TableName + N' ' + PrimaryKeyJson +
        N' Applied='' + CAST(@a AS nvarchar(5)) + N'' Conflict='' + CAST(@c AS nvarchar(5));' + NCHAR(13) + NCHAR(10) +
        N'END TRY BEGIN CATCH PRINT N''' + TableName + N' ' + PrimaryKeyJson +
        N' FAIL: '' + ERROR_MESSAGE(); END CATCH;' + NCHAR(13) + NCHAR(10)
    AS nvarchar(max)) AS SqlBatch
FROM ranked
WHERE rn = 1
ORDER BY
    CASE TableName WHEN N'PurchaseHead' THEN 0 ELSE 1 END,
    PrimaryKeyJson;

PRINT N'';
PRINT N'LOCAL prep before pasting SqlBatch:';
PRINT N'  1) Fix_PurchaseC2L_LocalWinsUnblock.sql';
PRINT N'  2) DataSync_10_SyncApply_Generic.sql';
PRINT N'  3) CaptureCloud=0 for Purchase';
PRINT N'Then paste Head batches first, then Detail.';
PRINT N'Verify: SELECT ID FROM PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;';
GO
