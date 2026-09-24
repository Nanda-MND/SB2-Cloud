/*
  LOCAL SB1 — force-apply Purchase 2000000000 from Cloud outbox payload.
  Proves whether SyncApply_Generic can insert Purchase (Sale C2L already works).

  STEP 1 CLOUD:
    SELECT TOP 1 OutboxID, LEN(PayloadJson) Len, PayloadJson
    FROM dbo.SyncOutbox
    WHERE Direction=N'C2L' AND TableName=N'PurchaseHead'
      AND PrimaryKeyJson LIKE N'%2000000000%'
    ORDER BY OutboxID DESC;

    SELECT TOP 1 OutboxID, LEN(PayloadJson) Len, PayloadJson
    FROM dbo.SyncOutbox
    WHERE Direction=N'C2L' AND TableName=N'PurchaseDetail'
      AND PrimaryKeyJson LIKE N'%2000000000%'
    ORDER BY OutboxID DESC;

  STEP 2 LOCAL — paste payloads, then run this batch.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Paste from Cloud (required)
DECLARE @HeadJson nvarchar(max) = NULL;   -- N'{...}'
DECLARE @DetailJson nvarchar(max) = NULL; -- N'{...}'

IF @HeadJson IS NULL OR LEN(@HeadJson) < 10
BEGIN
    PRINT 'Paste PurchaseHead PayloadJson into @HeadJson first.';
    -- Show wrapper health while waiting
    SELECT name, modify_date FROM sys.procedures
    WHERE name IN (N'SyncApply_Generic', N'SyncApply_PurchaseHead', N'SyncApply_PurchaseDetail');
    SELECT LEFT(OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_PurchaseHead')), 400) AS PurchaseHeadWrapper;
    RETURN;
END

DECLARE @Conflict bit, @Applied bit;

BEGIN TRY
    SET @Conflict = 0; SET @Applied = 0;
    EXEC dbo.SyncApply_Generic
        @Source = N'Cloud',
        @TableName = N'PurchaseHead',
        @PayloadJson = @HeadJson,
        @PrimaryKeyJson = N'{"ID":2000000000}',
        @RemoteModifiedAt = SYSUTCDATETIME(),
        @Operation = N'I',
        @OutboxID = NULL,
        @ConflictLogged = @Conflict OUTPUT,
        @Applied = @Applied OUTPUT;
    PRINT 'Head Applied=' + CAST(ISNULL(@Applied,0) AS nvarchar(5))
        + N' Conflict=' + CAST(ISNULL(@Conflict,0) AS nvarchar(5));
END TRY
BEGIN CATCH
    PRINT 'Head FAIL: ' + ERROR_MESSAGE();
END CATCH

IF @DetailJson IS NOT NULL AND LEN(@DetailJson) > 10
BEGIN
    BEGIN TRY
        SET @Conflict = 0; SET @Applied = 0;
        EXEC dbo.SyncApply_Generic
            @Source = N'Cloud',
            @TableName = N'PurchaseDetail',
            @PayloadJson = @DetailJson,
            @PrimaryKeyJson = N'{"ID":2000000000}',
            @RemoteModifiedAt = SYSUTCDATETIME(),
            @Operation = N'I',
            @OutboxID = NULL,
            @ConflictLogged = @Conflict OUTPUT,
            @Applied = @Applied OUTPUT;
        PRINT 'Detail Applied=' + CAST(ISNULL(@Applied,0) AS nvarchar(5))
            + N' Conflict=' + CAST(ISNULL(@Conflict,0) AS nvarchar(5));
    END TRY
    BEGIN CATCH
        PRINT 'Detail FAIL: ' + ERROR_MESSAGE();
    END CATCH
END

SELECT ID, SyncOrigin, Remark FROM dbo.PurchaseHead WHERE ID = 2000000000;
SELECT ID, RefID, CodeID, Qty FROM dbo.PurchaseDetail WHERE RefID = 2000000000;
GO
