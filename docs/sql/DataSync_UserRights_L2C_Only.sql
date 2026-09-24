/*
  UserRights → L2C only (disable C2L).

  Local edits push to Cloud (L2C).
  Cloud edits must NOT push back to Local (C2L off).

  Run on CLOUD first (db that has CaptureCloud / C2L triggers).
  Then run LOCAL verify section (or whole script — Local parts are safe).

  sqlcmd ... -i DataSync_UserRights_L2C_Only.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'=== BEFORE: UserRights SyncConfig ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName = N'UserRights';

-- 1) Drop C2L cloud-capture trigger if present
IF OBJECT_ID(N'dbo.tr_SyncOutbox_UserRights', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.tr_SyncOutbox_UserRights;
    PRINT N'Dropped trigger dbo.tr_SyncOutbox_UserRights';
END
ELSE
    PRINT N'No tr_SyncOutbox_UserRights (ok).';

-- Alternate naming used by some installers
IF OBJECT_ID(N'dbo.tr_SyncCaptureCloud_UserRights', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.tr_SyncCaptureCloud_UserRights;
    PRINT N'Dropped trigger dbo.tr_SyncCaptureCloud_UserRights';
END

-- 2) SyncConfig: keep inbound L2C apply enabled; turn off C2L capture
IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'UserRights')
BEGIN
    UPDATE dbo.SyncConfig
    SET CaptureCloud = 0,
        IsEnabled = 1,
        Notes = LEFT(
            CONCAT(ISNULL(Notes, N''), N' | UserRights L2C-only ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)),
            500)
    WHERE TableName = N'UserRights';
    PRINT N'SyncConfig UserRights: CaptureCloud=0, IsEnabled=1';
END
ELSE
BEGIN
    INSERT INTO dbo.SyncConfig
        (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
    VALUES
        (N'UserRights', 1, 0, 0, N'ID', 100, 30, N'L2C inbound apply only (no C2L)');
    PRINT N'Inserted SyncConfig UserRights (L2C apply only).';
END

-- 3) Clear pending C2L outbox for UserRights (do not push Cloud→Local)
DELETE FROM dbo.SyncOutbox
WHERE TableName = N'UserRights'
  AND Direction = N'C2L'
  AND Status IN (N'Pending', N'Syncing');
PRINT N'Cleared pending C2L UserRights outbox: ' + CAST(@@ROWCOUNT AS nvarchar(10));

PRINT N'=== AFTER: UserRights SyncConfig ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName = N'UserRights';

PRINT N'=== C2L triggers still on UserRights? (expect 0) ===';
SELECT name
FROM sys.triggers
WHERE parent_id = OBJECT_ID(N'dbo.UserRights')
  AND name LIKE N'%Sync%';

PRINT N'Done on this DB.';
PRINT N'';
PRINT N'LOCAL (office SB1) — ensure L2C capture stays ON:';
PRINT N'  UPDATE dbo.SyncConfig';
PRINT N'  SET IsEnabled=1, CaptureLocal=1, CaptureCloud=0';
PRINT N'  WHERE TableName=N''UserRights'';';
PRINT N'';
PRINT N'Expected:';
PRINT N'  LOCAL  IsEnabled=1 CaptureLocal=1 CaptureCloud=0  → L2C out';
PRINT N'  CLOUD  IsEnabled=1 CaptureLocal=0 CaptureCloud=0  → L2C apply in, no C2L out';
GO
