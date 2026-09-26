/*======================================================================
  AcctSubGroup.SubGroupCode — optional subgroup display/filter code
======================================================================*/
SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.AcctSubGroup', N'SubGroupCode') IS NULL
BEGIN
    ALTER TABLE dbo.AcctSubGroup ADD SubGroupCode nvarchar(50) NULL;
    PRINT '[OK] Added AcctSubGroup.SubGroupCode';
END
ELSE
    PRINT '[SKIP] AcctSubGroup.SubGroupCode already exists';

PRINT '[DONE] AcctSubGroup_SubGroupCode';
GO
