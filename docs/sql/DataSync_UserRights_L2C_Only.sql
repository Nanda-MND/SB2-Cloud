/*
  CLOUD ONLY — UserRights L2C apply in, C2L off.

  Run this on Test Cloud after the Dev Local backup is restored.
  Do not run it on Dev Local. The restored copy still has CaptureLocal=1
  and local sync triggers (including tr_UserRights_SyncMetadata). This script
  turns those off on the cloud database.

  Local keeps CaptureLocal=1 via DataSync_UserRights_L2C_Only_Local.sql.

  Expected after this file:
    CLOUD  IsEnabled=1 CaptureLocal=0 CaptureCloud=0  and no UserRights %Sync% trigger
    LOCAL  IsEnabled=1 CaptureLocal=1 CaptureCloud=0  (set by the Local script, not this one)
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'=== BEFORE: UserRights SyncConfig ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName = N'UserRights';

-- 1) Drop every UserRights trigger the Test Cloud assert treats as sync capture.
--    Restored local names include tr_UserRights_SyncMetadata, tr_SyncOutbox_UserRights,
--    and tr_SyncCaptureCloud_UserRights.
DECLARE @drop nvarchar(max) = N'';
SELECT @drop = @drop
    + N'DROP TRIGGER ' + QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) + N';' + CHAR(10)
FROM sys.triggers AS t
WHERE t.parent_id = OBJECT_ID(N'dbo.UserRights')
  AND t.name LIKE N'%Sync%';

IF LEN(@drop) > 0
BEGIN
    PRINT N'Dropping UserRights sync triggers:';
    PRINT @drop;
    EXEC sys.sp_executesql @drop;
END
ELSE
    PRINT N'No UserRights %Sync% triggers (ok).';

-- 2) Cloud SyncConfig: inbound L2C apply stays on. Local capture and C2L capture stay off.
--    A restore from Dev Local leaves CaptureLocal=1. That must be cleared here.
IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'UserRights')
BEGIN
    UPDATE dbo.SyncConfig
    SET CaptureLocal = 0,
        CaptureCloud = 0,
        IsEnabled = 1,
        Notes = LEFT(
            CONCAT(ISNULL(Notes, N''), N' | Cloud UserRights L2C-apply only ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)),
            500)
    WHERE TableName = N'UserRights';
    PRINT N'SyncConfig UserRights: CaptureLocal=0, CaptureCloud=0, IsEnabled=1';
END
ELSE
BEGIN
    INSERT INTO dbo.SyncConfig
        (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
    VALUES
        (N'UserRights', 1, 0, 0, N'ID', 100, 30, N'Cloud L2C apply only (no local capture, no C2L)');
    PRINT N'Inserted SyncConfig UserRights (CaptureLocal=0, CaptureCloud=0, IsEnabled=1).';
END

-- 3) Clear pending C2L outbox for UserRights (do not push Cloud to Local)
DELETE FROM dbo.SyncOutbox
WHERE TableName = N'UserRights'
  AND Direction = N'C2L'
  AND Status IN (N'Pending', N'Syncing');
PRINT N'Cleared pending C2L UserRights outbox: ' + CAST(@@ROWCOUNT AS nvarchar(10));

PRINT N'=== AFTER: UserRights SyncConfig ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName = N'UserRights';

PRINT N'=== UserRights %Sync% triggers still present? (expect 0) ===';
SELECT name
FROM sys.triggers
WHERE parent_id = OBJECT_ID(N'dbo.UserRights')
  AND name LIKE N'%Sync%';

PRINT N'Done on this cloud DB.';
PRINT N'Dev Local must keep CaptureLocal=1. That is DataSync_UserRights_L2C_Only_Local.sql, not this file.';
GO
