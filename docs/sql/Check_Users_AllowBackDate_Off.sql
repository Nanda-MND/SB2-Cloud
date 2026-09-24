/*
  LIVE check — Users with AllowBackDate = 0
  Run on LOCAL (and Cloud if Users sync / Cloud login used).

  Why: Entry Save will soon require AllowBackDate + LogDay for MenuID=2
  when AllowEdit=1. Users with AllowBackDate=0 cannot save dates
  before Setting.Date — list them before enabling that gate everywhere.

  Read-only. No updates.
*/

SET NOCOUNT ON;

PRINT N'=== Setting.Date / LogDay window ===';
SELECT
    S.Date AS SettingDate,
    S.LogDay,
    MinDate = DATEADD(DAY, -S.LogDay, S.Date),
    MaxDate = DATEADD(DAY,  S.LogDay, S.Date)
FROM dbo.Setting S
WHERE S.ID = 1
   OR S.ID = (SELECT MIN(ID) FROM dbo.Setting);

PRINT N'=== Users AllowBackDate = 0 (active) ===';
SELECT
    U.ID AS UserID,
    U.Name AS UserName,
    U.AllowBackDate,
    U.InActive
FROM dbo.Users U
WHERE ISNULL(U.AllowBackDate, 0) = 0
  AND ISNULL(U.InActive, 0) <> 1
ORDER BY U.ID;

PRINT N'=== Those users — Entry rights (MenuID=2) AllowEdit / AllowDelete / AllowTransaction ===';
SELECT
    U.ID AS UserID,
    U.Name AS UserName,
    UR.MenuSubID,
    Menu = M.Name,
    UR.AllowTransaction,
    UR.AllowEdit,
    UR.AllowDelete
FROM dbo.Users U
INNER JOIN dbo.UserRights UR ON UR.UserID = U.ID AND UR.MenuID = 2
LEFT JOIN dbo.MenuSub M ON M.TypeID = 2 AND M.MenuID = UR.MenuSubID
WHERE ISNULL(U.AllowBackDate, 0) = 0
  AND ISNULL(U.InActive, 0) <> 1
ORDER BY U.ID, UR.MenuSubID;

PRINT N'=== Count summary ===';
SELECT
    BackDateOff_ActiveUsers =
        (SELECT COUNT(*) FROM dbo.Users
         WHERE ISNULL(AllowBackDate, 0) = 0 AND ISNULL(InActive, 0) <> 1),
    BackDateOff_WithEntryEdit =
        (SELECT COUNT(DISTINCT U.ID)
         FROM dbo.Users U
         INNER JOIN dbo.UserRights UR ON UR.UserID = U.ID AND UR.MenuID = 2
         WHERE ISNULL(U.AllowBackDate, 0) = 0
           AND ISNULL(U.InActive, 0) <> 1
           AND ISNULL(UR.AllowEdit, 0) = 1);

PRINT N'Done. Review users who have AllowEdit=1 and AllowBackDate=0 — they will be blocked from saving back-dated vouchers after MenuID=2 LogDay/BackDate gate goes live.';
GO
