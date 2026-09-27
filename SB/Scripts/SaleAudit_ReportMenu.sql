/*
  Register Sale Edit/Delete Log under Reports menu.
  ReportID 1160 = group, 1161 = report.
  Safe to re-run on live DB.
*/
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1160)
BEGIN
    BEGIN TRY
        SET IDENTITY_INSERT dbo.ReportName ON;
        INSERT INTO dbo.ReportName (ID, isRoot, RefID, Name, isVisible, SortID)
        VALUES
            (1160, 1, 0,    N'Sales Audit Reports', 1, 35),
            (1161, 0, 1160, N'Sale Edit/Delete Log', 1, 1);
        SET IDENTITY_INSERT dbo.ReportName OFF;
        DECLARE @MaxReportID INT = (SELECT MAX(ID) FROM dbo.ReportName);
        DBCC CHECKIDENT (N'dbo.ReportName', RESEED, @MaxReportID);
        PRINT '[OK] ReportName 1160-1161';
    END TRY
    BEGIN CATCH
        SET IDENTITY_INSERT dbo.ReportName OFF;
        THROW;
    END CATCH
END
ELSE
    PRINT '[SKIP] ReportName 1160 already exists';
GO

-- Rights only for UserID 1 and 3 (not copied from all sales-report users).
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
PRINT '[OK] UserRights 1160-1161 for UserID 1,3 only';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE TypeID = 3 AND MenuID = 1160 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (3, N'Sales Audit Reports', 1160, 0, NULL);

IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE TypeID = 3 AND MenuID = 1161 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (3, N'Sale Edit/Delete Log', 1161, 0, NULL);

PRINT '[OK] MenuSub 1160-1161';
GO

PRINT '[OK] SaleAudit_ReportMenu done';
GO
