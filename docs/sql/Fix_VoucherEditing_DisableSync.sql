/*
  LOCAL + CLOUD — VoucherEditing must NOT C2L.

  Session lock table (MenuID, TranID, UserID). SyncOrigin=2 rows on Local
  mean Cloud edit-locks were pulled C2L → false "Editing By …" popups.

  Run on BOTH Local SB1 and Cloud warehouse.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== ' + DB_NAME() + N' — disable VoucherEditing sync capture ===';

IF OBJECT_ID(N'dbo.VoucherEditing', N'U') IS NULL
BEGIN
    RAISERROR(N'VoucherEditing table not found.', 16, 1);
    RETURN;
END

-- Show current config / locks
IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NOT NULL
    SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Notes
    FROM dbo.SyncConfig
    WHERE TableName = N'VoucherEditing';

SELECT TOP 50 ID, MenuID, TranID, UserID, SyncOrigin, SyncModifiedAt
FROM dbo.VoucherEditing
ORDER BY ID DESC;
GO

-- Disable capture both ways (keep IsEnabled=0 so Agent skips apply too)
IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'VoucherEditing')
        UPDATE dbo.SyncConfig
        SET IsEnabled = 0,
            CaptureLocal = 0,
            CaptureCloud = 0,
            Notes = LEFT(CONCAT(N'Locks local-only; C2L/L2C off ',
                                CONVERT(nvarchar(30), SYSUTCDATETIME(), 126),
                                N' | ', ISNULL(Notes, N'')), 500)
        WHERE TableName = N'VoucherEditing';
    ELSE
        INSERT INTO dbo.SyncConfig (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, Notes)
        VALUES (N'VoucherEditing', 0, 0, 0, N'ID',
                N'Locks local-only; inserted disabled ' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126));
    PRINT N'SyncConfig VoucherEditing: IsEnabled=0 CaptureLocal=0 CaptureCloud=0';
END
GO

-- Drop C2L / L2C capture triggers if present
IF OBJECT_ID(N'dbo.tr_SyncOutbox_VoucherEditing', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.tr_SyncOutbox_VoucherEditing;
    PRINT N'Dropped tr_SyncOutbox_VoucherEditing';
END
IF OBJECT_ID(N'dbo.tr_SyncCaptureCloud_VoucherEditing', N'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.tr_SyncCaptureCloud_VoucherEditing;
    PRINT N'Dropped tr_SyncCaptureCloud_VoucherEditing';
END
GO

-- Cancel pending outbox either direction
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
BEGIN
    UPDATE dbo.SyncOutbox
    SET Status = N'Synced',
        LastError = N'Cancelled: VoucherEditing must not sync',
        SyncedAt = SYSUTCDATETIME()
    WHERE TableName = N'VoucherEditing'
      AND Status IN (N'Pending', N'Syncing', N'Conflict');
    PRINT N'Outbox cancelled: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END
GO

PRINT N'';
PRINT N'LOCAL only — clear ghost locks (Cloud-origin SyncOrigin=2 or stale):';
PRINT N'  DELETE FROM dbo.VoucherEditing WHERE SyncOrigin = 2;';
PRINT N'  -- or: DELETE FROM dbo.VoucherEditing WHERE UserID = 14;';
PRINT N'  -- or: DELETE FROM dbo.VoucherEditing WHERE TranID >= 2000000000;';
PRINT N'Do NOT use UserID=6 if SELECT showed UserID=14.';
GO
