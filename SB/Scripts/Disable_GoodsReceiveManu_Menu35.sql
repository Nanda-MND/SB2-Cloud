/*======================================================================
  Disable Manufacture > Goods Receive (menu 35) for ALL users
  CheckUserRights(UserID, 2, 35, 5) must return 0 to hide the tab.

  Run on ERP DB (not master). Safe to re-run.
======================================================================*/
SET NOCOUNT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database first.', 16, 1);
    SET NOEXEC ON;
END
GO

UPDATE dbo.UserRights
SET
    AllowTransaction = 0,
    AllowEdit        = 0,
    AllowDelete      = 0,
    AllowPrint       = 0,
    AllowExport      = 0
WHERE MenuID = 2
  AND MenuSubID = 35;

PRINT 'OK: Disabled Goods Receive (Manu) menu 35 for all users (rows=' + CAST(@@ROWCOUNT AS varchar(20)) + ')';
GO

SELECT UserID, AllowTransaction
FROM dbo.UserRights
WHERE MenuID = 2 AND MenuSubID = 35
ORDER BY UserID;

SELECT dbo.CheckUserRights(1, 2, 35, 5) AS ShouldBeZero;
GO
