-- Add Advance/Balance Check Report under Receivable Reports (RefID = 1021)
-- Report file: Reports\CustomerBalanceCheck.rpt
-- Data: dbo.SaleAdvBalanceCheck → dbo.SaleAdvBalanceAudit
--
-- Deploy on Local SB1 (and Cloud if ReportName/UserRights sync from local).

SET NOCOUNT ON;

DECLARE @ReportID int = 1154;
DECLARE @RefID    int = 1021; -- Receivable Reports
DECLARE @Name     nvarchar(100) = N'Advance/Balance Check Report';
DECLARE @SortID   int = 6;

IF NOT EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = @ReportID)
BEGIN
    SET IDENTITY_INSERT dbo.ReportName ON;
    INSERT INTO dbo.ReportName
    (
        ID, isRoot, RefID, Name, isVisible, SortID,
        FileName, cmdSel, cmdWh, cmdGb, cmdOb
    )
    VALUES
    (
        @ReportID, 0, @RefID, @Name, 1, @SortID,
        N'CustomerBalanceCheck.rpt', NULL, NULL, NULL, NULL
    );
    SET IDENTITY_INSERT dbo.ReportName OFF;
END
ELSE
BEGIN
    UPDATE dbo.ReportName
    SET Name = @Name,
        RefID = @RefID,
        isRoot = 0,
        isVisible = 1,
        SortID = @SortID,
        FileName = N'CustomerBalanceCheck.rpt'
    WHERE ID = @ReportID;
END

SELECT R.ID, R.Name, R.RefID, R.SortID, R.FileName, R.isVisible
FROM dbo.ReportName R
WHERE R.ID = @ReportID;

-- MenuSub required for Users Setup > Reports tab
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE TypeID = 3 AND MenuID = @ReportID)
BEGIN
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted)
    VALUES (3, @Name, @ReportID, 0);
END
ELSE
BEGIN
    UPDATE dbo.MenuSub
    SET Name = @Name, Deleted = 0
    WHERE TypeID = 3 AND MenuID = @ReportID;
END

-- All active users get this report right
INSERT INTO dbo.UserRights
(
    UserID, MenuSubID, MenuID,
    AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
    Reprint, DateChange, AllowExportDOC, AllowExportPDF
)
SELECT
    U.ID,
    @ReportID,
    3,
    1, 1, 1, 1, 1,
    1, 1, 1, 1
FROM dbo.Users U
WHERE ISNULL(U.Deleted, 0) <> 1
  AND ISNULL(U.IsDeleted, 0) <> 1
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.UserRights X
      WHERE X.UserID = U.ID
        AND X.MenuID = 3
        AND X.MenuSubID = @ReportID
  );

UPDATE dbo.UserRights
SET AllowTransaction = 1,
    AllowPrint = 1,
    AllowExport = 1
WHERE MenuID = 3
  AND MenuSubID = @ReportID;

SELECT MS.ID, MS.TypeID, MS.Name, MS.MenuID
FROM dbo.MenuSub MS
WHERE MS.TypeID = 3 AND MS.MenuID = @ReportID;

SELECT Cnt = COUNT(*) FROM dbo.UserRights WHERE MenuID = 3 AND MenuSubID = @ReportID;
GO
