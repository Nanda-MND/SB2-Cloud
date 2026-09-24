/*
  UserID 14 rights lockdown:
    - SETUP (MenuID = 1): remove ALL
    - REPORTS (MenuID = 3): keep ONLY
        1037 = Stock Balance
        1040 = Stock Balance (Without Brand)
        1079 = Stock Issue By Each Invoice
      remove every other report right

  Entry/Transaction rights (MenuID = 2) are left unchanged.

  Run on LOCAL SB1 (L2C pushes UserRights if sync enabled).
  Also run on Cloud if Cloud login must match immediately.

  To grant 1079 only (without full lockdown), use:
    Grant_UserRights_StockIssueByInvoice_14_16.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @UserID int = 14;
DECLARE @StockBalance int = 1037;
DECLARE @StockBalanceNoBrand int = 1040;
DECLARE @StockIssueByInvoice int = 1079;

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @UserID)
BEGIN
    RAISERROR(N'UserID %d not found.', 16, 1, @UserID);
    RETURN;
END

PRINT N'=== BEFORE: User ' + CAST(@UserID AS nvarchar(10)) + N' ===';

SELECT Kind = N'Setup', Cnt = COUNT(*)
FROM dbo.UserRights
WHERE UserID = @UserID AND MenuID = 1
UNION ALL
SELECT Kind = N'Reports', Cnt = COUNT(*)
FROM dbo.UserRights
WHERE UserID = @UserID AND MenuID = 3;

SELECT
    UR.MenuSubID,
    Menu = ISNULL(MS.Name, R.Name),
    UR.AllowTransaction
FROM dbo.UserRights UR
LEFT JOIN dbo.MenuSub MS ON MS.TypeID = 1 AND MS.MenuID = UR.MenuSubID
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.UserID = @UserID
  AND UR.MenuID = 1
ORDER BY UR.MenuSubID;

SELECT
    UR.MenuSubID,
    R.Name,
    UR.AllowTransaction
FROM dbo.UserRights UR
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.UserID = @UserID
  AND UR.MenuID = 3
ORDER BY UR.MenuSubID;

BEGIN TRAN;

-- 1) Remove ALL Setup rights
DELETE FROM dbo.UserRights
WHERE UserID = @UserID
  AND MenuID = 1;

PRINT N'Deleted Setup rights: ' + CAST(@@ROWCOUNT AS nvarchar(10));

-- 2) Remove every report right except Stock Balance + Stock Issue By Each Invoice
DELETE FROM dbo.UserRights
WHERE UserID = @UserID
  AND MenuID = 3
  AND MenuSubID NOT IN (@StockBalance, @StockBalanceNoBrand, @StockIssueByInvoice);

PRINT N'Deleted other report rights: ' + CAST(@@ROWCOUNT AS nvarchar(10));

-- 2b) Deduplicate leftover report rights (same UserID+MenuSubID twice → tree doubles names)
;WITH d AS
(
    SELECT
        ID,
        rn = ROW_NUMBER() OVER (
            PARTITION BY UserID, MenuID, MenuSubID
            ORDER BY ID
        )
    FROM dbo.UserRights
    WHERE UserID = @UserID
      AND MenuID = 3
)
DELETE FROM d WHERE rn > 1;

PRINT N'Deleted duplicate report rights for user: ' + CAST(@@ROWCOUNT AS nvarchar(10));

-- Ensure Stock Balance (1037)
IF NOT EXISTS (
    SELECT 1 FROM dbo.UserRights
    WHERE UserID = @UserID AND MenuID = 3 AND MenuSubID = @StockBalance
)
BEGIN
    INSERT INTO dbo.UserRights
    (
        UserID, MenuSubID, MenuID,
        AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
        Reprint, DateChange, AllowExportDOC, AllowExportPDF
    )
    VALUES
    (
        @UserID, @StockBalance, 3,
        1, 0, 0, 1, 1,
        0, 0, 0, 1
    );
    PRINT N'Inserted Stock Balance (1037).';
END
ELSE
BEGIN
    UPDATE dbo.UserRights
    SET AllowTransaction = 1,
        AllowPrint = 1,
        AllowExport = 1
    WHERE UserID = @UserID AND MenuID = 3 AND MenuSubID = @StockBalance;
    PRINT N'Updated Stock Balance (1037) Allow=1.';
END

-- Ensure Stock Balance Without Brand (1040)
IF NOT EXISTS (
    SELECT 1 FROM dbo.UserRights
    WHERE UserID = @UserID AND MenuID = 3 AND MenuSubID = @StockBalanceNoBrand
)
BEGIN
    INSERT INTO dbo.UserRights
    (
        UserID, MenuSubID, MenuID,
        AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
        Reprint, DateChange, AllowExportDOC, AllowExportPDF
    )
    VALUES
    (
        @UserID, @StockBalanceNoBrand, 3,
        1, 0, 0, 1, 1,
        0, 0, 0, 1
    );
    PRINT N'Inserted Stock Balance Without Brand (1040).';
END
ELSE
BEGIN
    UPDATE dbo.UserRights
    SET AllowTransaction = 1,
        AllowPrint = 1,
        AllowExport = 1
    WHERE UserID = @UserID AND MenuID = 3 AND MenuSubID = @StockBalanceNoBrand;
    PRINT N'Updated Stock Balance Without Brand (1040) Allow=1.';
END

-- Ensure Stock Issue By Each Invoice (1079)
IF NOT EXISTS (
    SELECT 1 FROM dbo.UserRights
    WHERE UserID = @UserID AND MenuID = 3 AND MenuSubID = @StockIssueByInvoice
)
BEGIN
    INSERT INTO dbo.UserRights
    (
        UserID, MenuSubID, MenuID,
        AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
        Reprint, DateChange, AllowExportDOC, AllowExportPDF
    )
    VALUES
    (
        @UserID, @StockIssueByInvoice, 3,
        1, 0, 0, 1, 1,
        0, 0, 0, 1
    );
    PRINT N'Inserted Stock Issue By Each Invoice (1079).';
END
ELSE
BEGIN
    UPDATE dbo.UserRights
    SET AllowTransaction = 1,
        AllowPrint = 1,
        AllowExport = 1
    WHERE UserID = @UserID AND MenuID = 3 AND MenuSubID = @StockIssueByInvoice;
    PRINT N'Updated Stock Issue By Each Invoice (1079) Allow=1.';
END

COMMIT TRAN;

PRINT N'=== AFTER: User ' + CAST(@UserID AS nvarchar(10)) + N' ===';

SELECT Kind = N'Setup', Cnt = COUNT(*)
FROM dbo.UserRights
WHERE UserID = @UserID AND MenuID = 1
UNION ALL
SELECT Kind = N'Reports', Cnt = COUNT(*)
FROM dbo.UserRights
WHERE UserID = @UserID AND MenuID = 3;

SELECT
    UR.MenuSubID,
    R.Name,
    UR.AllowTransaction,
    UR.AllowPrint
FROM dbo.UserRights UR
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.UserID = @UserID
  AND UR.MenuID = 3
ORDER BY UR.MenuSubID;

SELECT ID, Name, RefID, isRoot, isVisible
FROM dbo.ReportName
WHERE ID IN (@StockBalance, @StockBalanceNoBrand, @StockIssueByInvoice);

PRINT N'Done.';
PRINT N'  Setup  = 0 rights';
PRINT N'  Reports = Stock Balance + Without Brand + Stock Issue By Each Invoice';
PRINT N'Re-login as User 14 to refresh menus.';
GO
