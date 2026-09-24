/*
  UserRights ONLY — remove 2x duplicate rows on BOTH Local and Cloud.

  Key: (UserID, MenuID, MenuSubID) must be unique.
  Keep: lowest ID per key (stable). Prefer SyncOrigin=1 (Local) when tied by also
        ordering SyncOrigin ASC NULLs last, then ID.

  Run order:
    1) LOCAL SB1  — docs/sql/Fix_Duplicate_UserRights_BothSides.sql
    2) CLOUD      — same script (clean now; L2C may also push deletes)

  Does not change Users / LogInClient / other tables.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== DB: ' + DB_NAME() + N' ===';
PRINT N'=== BEFORE: duplicate UserRights (all MenuID) ===';

SELECT
    UR.UserID,
    UR.MenuID,
    UR.MenuSubID,
    Cnt = COUNT(*),
    MinID = MIN(UR.ID),
    MaxID = MAX(UR.ID)
FROM dbo.UserRights UR
GROUP BY UR.UserID, UR.MenuID, UR.MenuSubID
HAVING COUNT(*) > 1
ORDER BY UR.UserID, UR.MenuID, UR.MenuSubID;

DECLARE @DupCnt int =
(
    SELECT COUNT(*)
    FROM (
        SELECT UserID, MenuID, MenuSubID
        FROM dbo.UserRights
        GROUP BY UserID, MenuID, MenuSubID
        HAVING COUNT(*) > 1
    ) x
);
PRINT N'Duplicate keys: ' + CAST(@DupCnt AS nvarchar(10));

IF @DupCnt = 0
BEGIN
    PRINT N'No duplicates — nothing to delete.';
END
ELSE
BEGIN
    BEGIN TRAN;

    ;WITH ranked AS
    (
        SELECT
            ID,
            rn = ROW_NUMBER() OVER (
                PARTITION BY UserID, MenuID, MenuSubID
                ORDER BY
                    CASE WHEN SyncOrigin = 1 THEN 0 ELSE 1 END, -- prefer Local origin
                    ID
            )
        FROM dbo.UserRights
    )
    DELETE FROM ranked
    WHERE rn > 1;

    PRINT N'Deleted duplicate UserRights rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

    COMMIT TRAN;
END

PRINT N'=== AFTER: duplicate keys (expect 0) ===';
SELECT
    UR.UserID,
    UR.MenuID,
    UR.MenuSubID,
    Cnt = COUNT(*)
FROM dbo.UserRights UR
GROUP BY UR.UserID, UR.MenuID, UR.MenuSubID
HAVING COUNT(*) > 1
ORDER BY UR.UserID, UR.MenuID, UR.MenuSubID;

PRINT N'=== Spot-check User 14 / 16 Entry (MenuID=2) AllowEdit ===';
SELECT
    UR.UserID,
    UR.MenuID,
    UR.MenuSubID,
    Menu = M.Name,
    UR.AllowTransaction,
    UR.AllowEdit,
    UR.AllowDelete,
    UR.SyncOrigin
FROM dbo.UserRights UR
LEFT JOIN dbo.MenuSub M ON M.TypeID = UR.MenuID AND M.MenuID = UR.MenuSubID
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 2
ORDER BY UR.UserID, UR.MenuSubID;

PRINT N'=== Spot-check User 14 / 16 Reports (MenuID=3) ===';
SELECT
    UR.UserID,
    UR.MenuSubID,
    R.Name,
    UR.AllowTransaction,
    UR.SyncOrigin
FROM dbo.UserRights UR
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 3
ORDER BY UR.UserID, UR.MenuSubID;

PRINT N'Done on ' + DB_NAME() + N'.';
PRINT N'Run this same script on the other side (Local + Cloud).';
PRINT N'Re-login users after both sides are clean.';
GO
