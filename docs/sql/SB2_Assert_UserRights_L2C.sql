/*
  UserRights stays L2C-only.
  Local:  CaptureLocal=1, CaptureCloud=0
  Cloud:  CaptureCloud=0 and no UserRights sync trigger
  sqlcmd -v Role=Local   or   sqlcmd -v Role=TestCloud
*/
SET NOCOUNT ON;

DECLARE @role nvarchar(32) = N'$(Role)';

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
BEGIN
    RAISERROR(N'SyncConfig is missing.', 16, 1);
    RETURN;
END

IF @role = N'Local'
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.SyncConfig
        WHERE TableName = N'UserRights'
          AND IsEnabled = 1
          AND CaptureLocal = 1
          AND ISNULL(CaptureCloud, 0) = 0
    )
    BEGIN
        RAISERROR(N'UserRights must stay L2C-only on Dev Local (CaptureLocal=1, CaptureCloud=0).', 16, 1);
        RETURN;
    END
END
ELSE IF @role = N'TestCloud'
BEGIN
    IF EXISTS (
        SELECT 1
        FROM dbo.SyncConfig
        WHERE TableName = N'UserRights'
          AND ISNULL(CaptureCloud, 0) = 1
    )
    BEGIN
        RAISERROR(N'UserRights C2L must stay off on Test Cloud (CaptureCloud=0).', 16, 1);
        RETURN;
    END

    IF OBJECT_ID(N'dbo.UserRights', N'U') IS NOT NULL
       AND EXISTS (
            SELECT 1
            FROM sys.triggers
            WHERE parent_id = OBJECT_ID(N'dbo.UserRights')
              AND name LIKE N'%Sync%'
       )
    BEGIN
        RAISERROR(N'UserRights sync trigger must not exist on Test Cloud.', 16, 1);
        RETURN;
    END
END
ELSE
BEGIN
    RAISERROR(N'Role must be Local or TestCloud.', 16, 1);
    RETURN;
END

PRINT N'OK UserRights L2C-only (' + @role + N')';
GO
