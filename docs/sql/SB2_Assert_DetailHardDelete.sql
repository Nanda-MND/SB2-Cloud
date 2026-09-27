/*
  Detail Op=D is a hard delete (marker hardDeleteDetail).
  Head Op=D stays a soft delete (marker preserve-soft-delete-flags).

  Do not run this on an empty Dev database.
  Order: SB2_Run_LocalBootstrap.ps1 (Dev Local) or SB2_Run_CloudAfterRestore.ps1 (Test Cloud) first.
  Those runners call this file after SyncApply_Generic is installed.
*/
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
   OR OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    RAISERROR(N'precondition: SyncConfig or SyncApply_Generic missing - run SB2_Run_LocalBootstrap.ps1 before this assert.', 16, 1);
    RETURN;
END

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'));

IF @def NOT LIKE N'%hardDeleteDetail%'
BEGIN
    RAISERROR(N'Detail Op=D must be a hard delete. SyncApply_Generic is missing hardDeleteDetail. Re-run SB2_Run_LocalBootstrap.ps1.', 16, 1);
    RETURN;
END

IF @def NOT LIKE N'%preserve-soft-delete-flags%'
BEGIN
    RAISERROR(N'Head Op=D must stay a soft delete. SyncApply_Generic is missing preserve-soft-delete-flags. Re-run SB2_Run_LocalBootstrap.ps1.', 16, 1);
    RETURN;
END

PRINT N'OK Detail Op=D hard delete; Head Op=D soft delete.';
GO
