/*
  Fix: Foreign Currency Ledger (1162) UserRights flags were 0.
  CheckUserRights needs AllowTransaction = 1 to show the report.

  Run on SB2 — idempotent.
*/
SET NOCOUNT ON;

-- Ensure every user has a row
INSERT INTO dbo.UserRights
    (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
     Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT
    U.ID, 1162, 3,
    1, 0, 0, 1, 1,
    0, 0, 1, 1
FROM dbo.Users U
WHERE NOT EXISTS (
        SELECT 1 FROM dbo.UserRights X
        WHERE X.UserID = U.ID AND X.MenuSubID = 1162 AND X.MenuID = 3
  );

-- Enable view/print/export flags
UPDATE dbo.UserRights
SET
    AllowTransaction = 1,
    AllowPrint       = 1,
    AllowExport      = 1,
    AllowExportDOC   = 1,
    AllowExportPDF   = 1
WHERE MenuID = 3
  AND MenuSubID = 1162;

SELECT
    UserID,
    MenuSubID,
    AllowTransaction,
    AllowPrint,
    AllowExport,
    AllowExportDOC,
    AllowExportPDF
FROM dbo.UserRights
WHERE MenuID = 3 AND MenuSubID = 1162
ORDER BY UserID;

PRINT N'[OK] UserRights 1162 enabled for all users — reopen Reports menu.';
GO
