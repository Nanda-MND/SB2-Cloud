/*
  Fix duplicate Sale Edit/Delete Log in Reports tree + restrict rights to UserID 1, 3.
  Safe to re-run on live DB.
*/
SET NOCOUNT ON;
GO

/* 1) Deduplicate UserRights for 1160/1161 (keep lowest ID per UserID+MenuSubID+MenuID) */
;WITH d AS (
    SELECT ID,
           rn = ROW_NUMBER() OVER (
               PARTITION BY UserID, MenuSubID, MenuID
               ORDER BY ID
           )
    FROM dbo.UserRights
    WHERE MenuID = 3 AND MenuSubID IN (1160, 1161)
)
DELETE FROM dbo.UserRights
WHERE ID IN (SELECT ID FROM d WHERE rn > 1);
PRINT '[OK] Deduped UserRights 1160/1161';
GO

/* 2) Remove rights for everyone except UserID 1 and 3 */
DELETE FROM dbo.UserRights
WHERE MenuID = 3
  AND MenuSubID IN (1160, 1161)
  AND UserID NOT IN (1, 3);
PRINT '[OK] Removed 1160/1161 rights for users other than 1,3';
GO

/* 3) Ensure UserID 1 and 3 have AllowTransaction on 1160 + 1161 */
INSERT INTO dbo.UserRights
    (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
     Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT U.UserID, R.ID, 3, 1, 0, 0, 1, 1, 0, 0, 1, 1
FROM (VALUES (1), (3)) U(UserID)
CROSS JOIN (VALUES (1160), (1161)) R(ID)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.UserRights X
    WHERE X.UserID = U.UserID AND X.MenuSubID = R.ID AND X.MenuID = 3
);
PRINT '[OK] Ensured UserRights for UserID 1,3 on 1160/1161';
GO

/* 4) Soft-delete duplicate MenuSub rows for 1160/1161 (keep one) */
;WITH m AS (
    SELECT ID,
           rn = ROW_NUMBER() OVER (
               PARTITION BY TypeID, MenuID
               ORDER BY ID
           )
    FROM dbo.MenuSub
    WHERE TypeID = 3 AND MenuID IN (1160, 1161) AND ISNULL(Deleted, 0) = 0
)
UPDATE dbo.MenuSub
SET Deleted = 1
WHERE ID IN (SELECT ID FROM m WHERE rn > 1);
PRINT '[OK] Soft-deleted duplicate MenuSub 1160/1161';
GO

/* Verify */
SELECT 'UserRights' AS Src, UserID, MenuSubID, MenuID, AllowTransaction, COUNT(*) AS Cnt
FROM dbo.UserRights
WHERE MenuID = 3 AND MenuSubID IN (1160, 1161)
GROUP BY UserID, MenuSubID, MenuID, AllowTransaction
ORDER BY MenuSubID, UserID;

SELECT 'MenuSub' AS Src, ID, TypeID, MenuID, Name, Deleted
FROM dbo.MenuSub
WHERE TypeID = 3 AND MenuID IN (1160, 1161)
ORDER BY MenuID, ID;

SELECT 'ReportName' AS Src, ID, Name, isRoot, RefID, isVisible
FROM dbo.ReportName
WHERE ID IN (1160, 1161);
GO

PRINT '[DONE] SaleAudit_Fix_DuplicateAndRights_User1_3';
GO
