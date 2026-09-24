/*
  AcctSubGroup.SubGroupCode for Account Sub Group Setup (Account Code).
  Tree node text appends '-' + SubGroupCode after existing Name - [Short].

  Deploy on SB1. Restart app after deploy.
*/

SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.AcctSubGroup', N'SubGroupCode') IS NULL
BEGIN
    EXEC(N'ALTER TABLE dbo.AcctSubGroup ADD SubGroupCode nvarchar(50) NULL;');
    PRINT 'Added AcctSubGroup.SubGroupCode';
END
ELSE
    PRINT 'AcctSubGroup.SubGroupCode already exists';
GO

SELECT
    HasSubGroupCode = CASE WHEN COL_LENGTH(N'dbo.AcctSubGroup', N'SubGroupCode') IS NULL THEN 0 ELSE 1 END,
    FilledCnt = (SELECT COUNT(*) FROM dbo.AcctSubGroup WHERE ISNULL(SubGroupCode, N'') <> N'');
GO
