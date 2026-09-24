/*
  Fix duplicate report names in Reports tree.

  Cause: UserRights can have more than one row for the same
         (UserID, MenuID=3, MenuSubID) → JOIN in FillTreeView listed
         Stock Balance / Without Brand twice.

  1) Deduplicate UserRights (keep lowest ID per user+report)
  2) Spot-check Stock Balance reports 1037 / 1040 for User 14

  Run on LOCAL SB1 (and Cloud if needed).
  App fix: frm_Reports FillTreeView now uses EXISTS (not JOIN).
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'=== Duplicate ReportName under same parent (same Name) ===';
SELECT RefID, Name, Cnt = COUNT(*)
FROM dbo.ReportName
WHERE ISNULL(isRoot, 0) = 0
  AND ISNULL(isVisible, 0) = 1
GROUP BY RefID, Name
HAVING COUNT(*) > 1
ORDER BY RefID, Name;

-- Detail rows if any duplicates exist in ReportName
SELECT R.ID, R.RefID, R.Name, R.SortID, R.isVisible
FROM dbo.ReportName R
INNER JOIN (
    SELECT RefID, Name
    FROM dbo.ReportName
    WHERE ISNULL(isRoot, 0) = 0 AND ISNULL(isVisible, 0) = 1
    GROUP BY RefID, Name
    HAVING COUNT(*) > 1
) D ON D.RefID = R.RefID AND D.Name = R.Name
ORDER BY R.RefID, R.Name, R.ID;

PRINT N'=== Duplicate report UserRights (before) ===';
SELECT UserID, MenuSubID, Cnt = COUNT(*), Report = MAX(R.Name)
FROM dbo.UserRights UR
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.MenuID = 3
GROUP BY UserID, MenuSubID
HAVING COUNT(*) > 1
ORDER BY UserID, MenuSubID;

;WITH d AS
(
    SELECT
        ID,
        rn = ROW_NUMBER() OVER (
            PARTITION BY UserID, MenuID, MenuSubID
            ORDER BY ID
        )
    FROM dbo.UserRights
    WHERE MenuID = 3
)
DELETE FROM d
WHERE rn > 1;

PRINT N'Deleted duplicate report UserRights: ' + CAST(@@ROWCOUNT AS nvarchar(10));

PRINT N'=== Duplicate report UserRights (after — expect 0 rows) ===';
SELECT UserID, MenuSubID, Cnt = COUNT(*)
FROM dbo.UserRights
WHERE MenuID = 3
GROUP BY UserID, MenuSubID
HAVING COUNT(*) > 1;

-- User 14 Stock Balance check
PRINT N'=== User 14 report rights (Stock Balance) ===';
SELECT UR.ID, UR.UserID, UR.MenuSubID, R.Name, UR.AllowTransaction
FROM dbo.UserRights UR
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.UserID = 14
  AND UR.MenuID = 3
ORDER BY UR.MenuSubID;

PRINT N'Done. Rebuild/restart SB, reopen Reports — names should not duplicate.';
GO
