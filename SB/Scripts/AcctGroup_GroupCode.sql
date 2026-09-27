/*======================================================================
  AcctGroup.GroupCode — optional group display/filter code (falls back to Short)
======================================================================*/
SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.AcctGroup', N'GroupCode') IS NULL
BEGIN
    ALTER TABLE dbo.AcctGroup ADD GroupCode nvarchar(50) NULL;
    PRINT '[OK] Added AcctGroup.GroupCode';
END
ELSE
    PRINT '[SKIP] AcctGroup.GroupCode already exists';

PRINT '[DONE] AcctGroup_GroupCode';
GO
