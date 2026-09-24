/*
  Grant Sales report right to UserID 14 and 16:
    MenuID = 3 (Reports)
    MenuSubID = 1079 = Stock Issue By Each Invoice (StockIssue.rpt)

  Keeps existing rights (Stock Balance 1037/1040, etc.) — only adds/enables 1079.

  Run on LOCAL SB1 (L2C pushes UserRights if sync enabled).
  Also run on Cloud if Cloud login must match immediately.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

DECLARE @ReportID int = 1079;
DECLARE @ReportName nvarchar(200);

SELECT @ReportName = Name
FROM dbo.ReportName
WHERE ID = @ReportID;

IF @ReportName IS NULL
BEGIN
    RAISERROR(N'ReportName ID %d not found. Check Sales Reports / Stock Issue By Each Invoice.', 16, 1, @ReportID);
    RETURN;
END

PRINT N'Report: ID=' + CAST(@ReportID AS nvarchar(10)) + N' Name=' + @ReportName;

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

PRINT N'=== BEFORE ===';
SELECT UR.UserID, UR.MenuSubID, R.Name, UR.AllowTransaction, UR.AllowPrint
FROM dbo.UserRights UR
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 3
  AND UR.MenuSubID = @ReportID;

BEGIN TRAN;

-- User 14
IF EXISTS (
    SELECT 1 FROM dbo.UserRights
    WHERE UserID = 14 AND MenuID = 3 AND MenuSubID = @ReportID
)
BEGIN
    UPDATE dbo.UserRights
    SET AllowTransaction = 1,
        AllowPrint = 1,
        AllowExport = 1
    WHERE UserID = 14 AND MenuID = 3 AND MenuSubID = @ReportID;
    PRINT N'Updated User 14 right for ' + @ReportName;
END
ELSE
BEGIN
    INSERT INTO dbo.UserRights
    (
        UserID, MenuSubID, MenuID,
        AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
        Reprint, DateChange, AllowExportDOC, AllowExportPDF
    )
    VALUES
    (
        14, @ReportID, 3,
        1, 0, 0, 1, 1,
        0, 0, 0, 1
    );
    PRINT N'Inserted User 14 right for ' + @ReportName;
END

-- User 16
IF EXISTS (
    SELECT 1 FROM dbo.UserRights
    WHERE UserID = 16 AND MenuID = 3 AND MenuSubID = @ReportID
)
BEGIN
    UPDATE dbo.UserRights
    SET AllowTransaction = 1,
        AllowPrint = 1,
        AllowExport = 1
    WHERE UserID = 16 AND MenuID = 3 AND MenuSubID = @ReportID;
    PRINT N'Updated User 16 right for ' + @ReportName;
END
ELSE
BEGIN
    INSERT INTO dbo.UserRights
    (
        UserID, MenuSubID, MenuID,
        AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
        Reprint, DateChange, AllowExportDOC, AllowExportPDF
    )
    VALUES
    (
        16, @ReportID, 3,
        1, 0, 0, 1, 1,
        0, 0, 0, 1
    );
    PRINT N'Inserted User 16 right for ' + @ReportName;
END

-- Deduplicate if any double rows
;WITH d AS
(
    SELECT
        ID,
        rn = ROW_NUMBER() OVER (
            PARTITION BY UserID, MenuID, MenuSubID
            ORDER BY ID
        )
    FROM dbo.UserRights
    WHERE UserID IN (14, 16)
      AND MenuID = 3
      AND MenuSubID = @ReportID
)
DELETE FROM d WHERE rn > 1;

COMMIT TRAN;

PRINT N'=== AFTER (User 14/16 report rights) ===';
SELECT UR.UserID, UR.MenuSubID, R.Name, UR.AllowTransaction, UR.AllowPrint, UR.AllowExport
FROM dbo.UserRights UR
LEFT JOIN dbo.ReportName R ON R.ID = UR.MenuSubID
WHERE UR.UserID IN (14, 16)
  AND UR.MenuID = 3
ORDER BY UR.UserID, UR.MenuSubID;

PRINT N'Done. Re-login as User 14 / 16 to refresh Reports tree.';
GO
