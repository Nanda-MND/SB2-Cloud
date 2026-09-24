/*
  Force Setting row on CLOUD to match Local (one-time fix).

  Edit @Date below to match Local Setting.Date, then run on CLOUD only.
  Prefer SyncTest_ApplySetting_Cloud.sql or agent retry after DataSync_10 deploy.
*/

SET NOCOUNT ON;

DECLARE @Date datetime = N'2026-07-22 08:03:27.587';  -- Local Setting.Date

EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;

UPDATE dbo.Setting
SET [Date] = @Date,
    SyncModifiedAt = sysutcdatetime(),
    SyncOrigin = 1
WHERE ID = 1;

EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;

SELECT ID, [Date], SyncModifiedAt, SyncOrigin FROM dbo.Setting WHERE ID = 1;
GO
