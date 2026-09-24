/*
  Setting.Date Local -> Cloud (L2C) diagnostic.

  Run on LOCAL first, then CLOUD.

  Common cause: Local has C2L capture trigger (DataSync_29 mistake)
  -> Setting changes queue Direction=C2L on Local -> agent never pushes to Cloud.
*/

SET NOCOUNT ON;
PRINT '=== DB: ' + DB_NAME() + ' ===';

PRINT '=== 1. Setting row ===';
IF OBJECT_ID(N'dbo.Setting', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.Setting', N'Date') IS NOT NULL
        SELECT ID, [Date], LogDay, Name, SyncModifiedAt, SyncOrigin FROM dbo.Setting WHERE ID = 1;
    ELSE IF COL_LENGTH(N'dbo.Setting', N'SettingDate') IS NOT NULL
        SELECT ID, SettingDate, LogDay, Name, SyncModifiedAt, SyncOrigin FROM dbo.Setting WHERE ID = 1;
    ELSE
        SELECT TOP 1 * FROM dbo.Setting;
END

PRINT '=== 2. SyncConfig Setting ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig WHERE TableName = N'Setting';

PRINT '=== 3. Outbox Setting (ALL directions) ===';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
BEGIN
    SELECT Direction, Status, COUNT(*) AS Cnt
    FROM dbo.SyncOutbox WHERE TableName = N'Setting'
    GROUP BY Direction, Status ORDER BY Direction, Status;

    SELECT TOP 10 OutboxID, Direction, Status, Operation, CreatedAt, SyncedAt,
           LEFT(LastError, 120) AS LastError,
           LEFT(PayloadJson, 200) AS PayloadPreview
    FROM dbo.SyncOutbox WHERE TableName = N'Setting'
    ORDER BY OutboxID DESC;
END

PRINT '=== 4. Trigger type (CaptureLocal vs CaptureCloud) ===';
IF OBJECT_ID(N'dbo.tr_SyncOutbox_Setting', N'TR') IS NOT NULL
    SELECT name, LEFT(OBJECT_DEFINITION(object_id), 600) AS DefStart
    FROM sys.triggers WHERE name = N'tr_SyncOutbox_Setting';
ELSE
    PRINT 'MISSING tr_SyncOutbox_Setting';

PRINT '=== 5. CloudOnline / Agent ===';
IF OBJECT_ID(N'dbo.SyncState', N'U') IS NOT NULL
    SELECT StateKey, StateValue, UpdatedAt FROM dbo.SyncState WHERE StateKey = N'CloudOnline';
GO
