/*
  Test Setting L2C apply on CLOUD manually.

  1) Run on LOCAL — copy PayloadJson + SyncModifiedAt from latest L2C outbox:
     SELECT PayloadJson, SyncModifiedAt, PrimaryKeyJson
     FROM SyncOutbox WHERE OutboxID = 680314;  -- or latest Setting L2C

  2) Paste values below and run on CLOUD.
*/

SET NOCOUNT ON;

DECLARE @PayloadJson nvarchar(max) = N'PASTE_PAYLOAD_JSON_HERE';
DECLARE @PrimaryKeyJson nvarchar(500) = N'{"ID":1}';
DECLARE @RemoteModifiedAt datetime2(3) = N'2026-07-22 01:33:27.733';  -- from Local outbox SyncModifiedAt

DECLARE @Conflict bit, @Applied bit;

PRINT '=== Cloud BEFORE ===';
SELECT ID, [Date], SyncModifiedAt, SyncOrigin FROM dbo.Setting WHERE ID = 1;

EXEC dbo.SyncApply_Generic
    @Source = 'Local',
    @TableName = N'Setting',
    @PayloadJson = @PayloadJson,
    @PrimaryKeyJson = @PrimaryKeyJson,
    @RemoteModifiedAt = @RemoteModifiedAt,
    @Operation = NULL,
    @OutboxID = NULL,
    @ConflictLogged = @Conflict OUTPUT,
    @Applied = @Applied OUTPUT;

PRINT 'Applied=' + CAST(@Applied AS nvarchar(1)) + N' Conflict=' + CAST(@Conflict AS nvarchar(1));

PRINT '=== Cloud AFTER ===';
SELECT ID, [Date], SyncModifiedAt, SyncOrigin FROM dbo.Setting WHERE ID = 1;
GO
