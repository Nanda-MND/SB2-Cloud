/*
  Detail Op=D is a hard delete (marker hardDeleteDetail).
  Head Op=D stays a soft delete (marker preserve-soft-delete-flags).
*/
SET NOCOUNT ON;

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'));

IF @def IS NULL OR @def NOT LIKE N'%hardDeleteDetail%'
BEGIN
    RAISERROR(N'Detail Op=D must be a hard delete. SyncApply_Generic is missing hardDeleteDetail.', 16, 1);
    RETURN;
END

IF @def NOT LIKE N'%preserve-soft-delete-flags%'
BEGIN
    RAISERROR(N'Head Op=D must stay a soft delete. SyncApply_Generic is missing preserve-soft-delete-flags.', 16, 1);
    RETURN;
END

PRINT N'OK Detail Op=D hard delete; Head Op=D soft delete.';
GO
