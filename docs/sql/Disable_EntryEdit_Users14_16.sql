/*
  Disable ALL Entry Edit rights for UserID 14 and 16.

  MenuID = 2 = Entry / Transaction
  AllowEdit = 0 on every Entry row (new vouchers can still be allowed via AllowTransaction).

  Run on LOCAL SB1 (L2C pushes UserRights if sync enabled).
  Also run on Cloud if Cloud login must match immediately.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 14)
BEGIN
    RAISERROR(N'UserID 14 not found.', 16, 1);
    RETURN;
END
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 16)
BEGIN
    RAISERROR(N'UserID 16 not found.', 16, 1);
    RETURN;
END

PRINT N'=== BEFORE: Entry AllowEdit counts ===';
SELECT
    UR.UserID,
    EditOn = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 1 THEN 1 ELSE 0 END),
    EditOff = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 0 THEN 1 ELSE 0 END),
    TotalEntry = COUNT(*)
FROM dbo.UserRights UR
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 2
GROUP BY UR.UserID
ORDER BY UR.UserID;

SELECT
    UR.UserID,
    UR.MenuSubID,
    Menu = M.Name,
    UR.AllowTransaction,
    UR.AllowEdit,
    UR.AllowDelete
FROM dbo.UserRights UR
LEFT JOIN dbo.MenuSub M ON M.TypeID = 2 AND M.MenuID = UR.MenuSubID
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 2
  AND ISNULL(UR.AllowEdit, 0) = 1
ORDER BY UR.UserID, UR.MenuSubID;

BEGIN TRAN;

UPDATE dbo.UserRights
SET AllowEdit = 0
WHERE UserID IN (14, 16)
  AND MenuID = 2
  AND ISNULL(AllowEdit, 0) <> 0;

PRINT N'Updated rows (AllowEdit → 0): ' + CAST(@@ROWCOUNT AS nvarchar(10));

COMMIT TRAN;

PRINT N'=== AFTER: Entry AllowEdit counts (EditOn should be 0) ===';
SELECT
    UR.UserID,
    EditOn = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 1 THEN 1 ELSE 0 END),
    EditOff = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 0 THEN 1 ELSE 0 END),
    TotalEntry = COUNT(*)
FROM dbo.UserRights UR
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 2
GROUP BY UR.UserID
ORDER BY UR.UserID;

SELECT
    UR.UserID,
    UR.MenuSubID,
    Menu = M.Name,
    UR.AllowTransaction,
    UR.AllowEdit,
    UR.AllowDelete
FROM dbo.UserRights UR
LEFT JOIN dbo.MenuSub M ON M.TypeID = 2 AND M.MenuID = UR.MenuSubID
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 2
ORDER BY UR.UserID, UR.MenuSubID;

PRINT N'Done. Entry Edit disabled for User 14 and 16.';
PRINT N'Re-login as User 14 / 16 to refresh rights.';
GO
