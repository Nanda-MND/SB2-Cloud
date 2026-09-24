/*
  AcctGroup.GroupCode for Account Group Setup (Account Code field).
  Listview uses same MenuName=Account column AccountCode (alias of GroupCode).

  Deploy on SB1. Restart app after deploy.
*/

SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.AcctGroup', N'GroupCode') IS NULL
BEGIN
    EXEC(N'ALTER TABLE dbo.AcctGroup ADD GroupCode nvarchar(50) NULL;');
    PRINT 'Added AcctGroup.GroupCode';
END
ELSE
    PRINT 'AcctGroup.GroupCode already exists';
GO

SELECT
    HasGroupCode = CASE WHEN COL_LENGTH(N'dbo.AcctGroup', N'GroupCode') IS NULL THEN 0 ELSE 1 END,
    FilledCnt = (SELECT COUNT(*) FROM dbo.AcctGroup WHERE ISNULL(GroupCode, N'') <> N'');
GO
