/*
  LOCAL SB1 — UserRights L2C capture ON, C2L OFF.

  Run on OFFICE Local after Cloud script DataSync_UserRights_L2C_Only.sql.
*/

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'UserRights')
BEGIN
    INSERT INTO dbo.SyncConfig
        (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
    VALUES
        (N'UserRights', 1, 1, 0, N'ID', 100, 30, N'L2C only');
    PRINT N'Inserted SyncConfig UserRights (L2C capture).';
END
ELSE
BEGIN
    UPDATE dbo.SyncConfig
    SET IsEnabled = 1,
        CaptureLocal = 1,
        CaptureCloud = 0,
        Notes = LEFT(
            CONCAT(ISNULL(Notes, N''), N' | L2C-only ', CONVERT(nvarchar(30), SYSUTCDATETIME(), 126)),
            500)
    WHERE TableName = N'UserRights';
    PRINT N'Updated SyncConfig UserRights: CaptureLocal=1, CaptureCloud=0';
END

-- Local must never have Cloud C2L capture trigger
IF OBJECT_ID(N'dbo.tr_SyncOutbox_UserRights', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.tr_SyncOutbox_UserRights;
    PRINT N'Dropped local tr_SyncOutbox_UserRights (should not exist on Local).';
END

SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
FROM dbo.SyncConfig
WHERE TableName = N'UserRights';

PRINT N'Expected: IsEnabled=1, CaptureLocal=1, CaptureCloud=0';
GO
