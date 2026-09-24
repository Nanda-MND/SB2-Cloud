/*
  MenuID=2 (Entry): AllowDelete=1 only for UserID 1,2,3,4,5,8.
  All other users → AllowDelete=0.

  Run on LOCAL then CLOUD (or Local + L2C if UserRights syncs L2C-only).
*/

SET NOCOUNT ON;

PRINT N'=== BEFORE: who has AllowDelete=1 on MenuID=2 ===';
SELECT U.ID, U.Name,
       DeleteOn = SUM(CASE WHEN ISNULL(UR.AllowDelete,0)=1 THEN 1 ELSE 0 END),
       EntryRows = COUNT(*)
FROM dbo.UserRights UR
INNER JOIN dbo.Users U ON U.ID = UR.UserID
WHERE UR.MenuID = 2
  AND ISNULL(UR.AllowDelete,0) = 1
GROUP BY U.ID, U.Name
ORDER BY U.ID;

-- 1) Admins ON
UPDATE dbo.UserRights
SET AllowDelete = 1
WHERE MenuID = 2
  AND UserID IN (1, 2, 3, 4, 5, 8)
  AND ISNULL(AllowDelete, 0) <> 1;
PRINT N'AllowDelete=1 set for UserID 1,2,3,4,5,8: ' + CAST(@@ROWCOUNT AS nvarchar(20));

-- 2) Everyone else OFF (includes former admin 19, etc.)
UPDATE dbo.UserRights
SET AllowDelete = 0
WHERE MenuID = 2
  AND UserID NOT IN (1, 2, 3, 4, 5, 8)
  AND ISNULL(AllowDelete, 0) <> 0;
PRINT N'AllowDelete=0 cleared for other users: ' + CAST(@@ROWCOUNT AS nvarchar(20));

PRINT N'=== AFTER: AllowDelete=1 only ===';
SELECT U.ID, U.Name,
       DeleteOn = SUM(CASE WHEN ISNULL(UR.AllowDelete,0)=1 THEN 1 ELSE 0 END),
       EntryRows = COUNT(*)
FROM dbo.UserRights UR
INNER JOIN dbo.Users U ON U.ID = UR.UserID
WHERE UR.MenuID = 2
  AND ISNULL(UR.AllowDelete,0) = 1
GROUP BY U.ID, U.Name
ORDER BY U.ID;

PRINT N'Done. Expect only UserID 1,2,3,4,5,8. Re-login after deploy.';
GO
