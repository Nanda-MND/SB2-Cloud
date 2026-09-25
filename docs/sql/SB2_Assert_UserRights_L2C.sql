/*
  UserRights stays L2C-only.
  Local:  CaptureLocal=1, CaptureCloud=0
  Cloud:  CaptureCloud=0 and no UserRights sync trigger

  Do not run this file by itself on an empty Dev database.
  Order:
    1) SB2_Run_LocalBootstrap.ps1          calls this with  sqlcmd -v Role=Local
    2) SB2_Run_CloudAfterRestore.ps1       calls this with  sqlcmd -v Role=TestCloud
  A direct sqlcmd without -v Role= prints: Scripting variable not defined.
*/
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
BEGIN
    RAISERROR(N'precondition: SyncConfig missing - run SB2_Run_LocalBootstrap.ps1 before this assert.', 16, 1);
    RETURN;
END

DECLARE @role nvarchar(32) = N'$(Role)';

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
        RAISERROR(N'UserRights must stay L2C-only on Dev Local (CaptureLocal=1, CaptureCloud=0). Run SB2_Run_LocalBootstrap.ps1.', 16, 1);
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
        RAISERROR(N'UserRights C2L must stay off on Test Cloud (CaptureCloud=0). Run SB2_Run_CloudAfterRestore.ps1.', 16, 1);
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
    RAISERROR(N'Pass sqlcmd -v Role=Local or -v Role=TestCloud. SB2_Run_LocalBootstrap.ps1 and SB2_Run_CloudAfterRestore.ps1 already pass Role. Do not run this assert before bootstrap.', 16, 1);
    RETURN;
END

PRINT N'OK UserRights L2C-only (' + @role + N')';
GO
