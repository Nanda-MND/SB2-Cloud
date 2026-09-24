/*
  Clone UserRights: UserID 14 → UserID 16
  Run on LOCAL SB1 (L2C will push to Cloud if UserRights sync enabled).
  Also run on Cloud if you need immediate Cloud login rights before sync.
*/

SET NOCOUNT ON;

DECLARE @FromUser int = 14;
DECLARE @ToUser   int = 16;

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @FromUser)
BEGIN
    RAISERROR(N'Source UserID %d not found.', 16, 1, @FromUser);
    RETURN;
END
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @ToUser)
BEGIN
    RAISERROR(N'Target UserID %d not found.', 16, 1, @ToUser);
    RETURN;
END

PRINT '=== Before ===';
SELECT UserID, Cnt = COUNT(*)
FROM dbo.UserRights
WHERE UserID IN (@FromUser, @ToUser)
GROUP BY UserID;

BEGIN TRAN;

DELETE FROM dbo.UserRights WHERE UserID = @ToUser;

INSERT INTO dbo.UserRights
(
    UserID, MenuID, MenuSubID,
    AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
    Reprint, DateChange, AllowExportDOC, AllowExportPDF
)
SELECT
    @ToUser,
    MenuID, MenuSubID,
    AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
    Reprint, DateChange, AllowExportDOC, AllowExportPDF
FROM dbo.UserRights
WHERE UserID = @FromUser;

PRINT 'Inserted rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

COMMIT TRAN;

PRINT '=== After ===';
SELECT UserID, Cnt = COUNT(*)
FROM dbo.UserRights
WHERE UserID IN (@FromUser, @ToUser)
GROUP BY UserID;

-- Spot-check flags match
SELECT
    ISNULL(SUM(CASE WHEN a.AllowTransaction <> b.AllowTransaction THEN 1 ELSE 0 END), 0) AS DiffAllow,
    ISNULL(SUM(CASE WHEN a.AllowEdit <> b.AllowEdit THEN 1 ELSE 0 END), 0) AS DiffEdit,
    ISNULL(SUM(CASE WHEN a.AllowDelete <> b.AllowDelete THEN 1 ELSE 0 END), 0) AS DiffDelete
FROM dbo.UserRights a
INNER JOIN dbo.UserRights b
    ON b.UserID = @ToUser AND b.MenuID = a.MenuID AND b.MenuSubID = a.MenuSubID
WHERE a.UserID = @FromUser;

PRINT 'Diff* = 0 means User 16 matches User 14.';
PRINT 'Re-login as User 16 to refresh menus.';
GO
