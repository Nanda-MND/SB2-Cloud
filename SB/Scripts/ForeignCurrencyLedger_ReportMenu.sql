/*
  Foreign Currency Ledger — Reports menu (under General Ledger FOLDER)

  ReportID 1162
  Parent   = root ReportName "General Ledger" (same folder as GL Detail /
             Summary / Cash Bank Statement) — NOT Accounting Reports / 1133
  Rights   = ALL users in dbo.Users
  Idempotent — safe to re-run on live SB2.
*/
SET NOCOUNT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database (e.g. SB2) first.', 16, 1);
    RETURN;
END
GO

DECLARE @ReportID int = 1162;
DECLARE @ReportTitle nvarchar(200) = N'Foreign Currency Ledger';
DECLARE @ParentID int = NULL;
DECLARE @SortID int = 1;

-- Prefer root folder "General Ledger" (NOT Accounting Reports child 1133)
SELECT TOP (1) @ParentID = ID
FROM dbo.ReportName
WHERE ISNULL(isRoot, 0) = 1
  AND ISNULL(isVisible, 0) = 1
  AND LTRIM(RTRIM(Name)) = N'General Ledger'
ORDER BY SortID, ID;

-- Fallback: parent of GL Detail / Summary / Bank Statement
IF @ParentID IS NULL
    SELECT TOP (1) @ParentID = NULLIF(RefID, 0)
    FROM dbo.ReportName
    WHERE ID IN (1068, 1142, 1130, 1101, 1069, 1143)
      AND ISNULL(isRoot, 0) = 0
      AND ISNULL(RefID, 0) > 0
    ORDER BY CASE ID
        WHEN 1068 THEN 1 WHEN 1142 THEN 2 WHEN 1130 THEN 3 ELSE 9 END;

IF @ParentID IS NULL
    SELECT TOP (1) @ParentID = ID
    FROM dbo.ReportName
    WHERE ISNULL(isRoot, 0) = 1
      AND ISNULL(isVisible, 0) = 1
      AND Name LIKE N'%General Ledger%'
    ORDER BY SortID, ID;

IF @ParentID IS NULL
BEGIN
    RAISERROR(N'Could not find General Ledger folder in ReportName. Insert aborted.', 16, 1);
    RETURN;
END

SELECT @SortID = ISNULL(MAX(SortID), 0) + 1
FROM dbo.ReportName
WHERE RefID = @ParentID AND ISNULL(isRoot, 0) = 0 AND ID <> @ReportID;

IF NOT EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = @ReportID)
BEGIN
    BEGIN TRY
        SET IDENTITY_INSERT dbo.ReportName ON;
        INSERT INTO dbo.ReportName (ID, isRoot, RefID, Name, isVisible, SortID)
        VALUES (@ReportID, 0, @ParentID, @ReportTitle, 1, @SortID);
        SET IDENTITY_INSERT dbo.ReportName OFF;

        DECLARE @MaxReportID int = (SELECT MAX(ID) FROM dbo.ReportName);
        DBCC CHECKIDENT (N'dbo.ReportName', RESEED, @MaxReportID);

        PRINT N'[OK] ReportName ' + CAST(@ReportID AS nvarchar(20))
            + N' under parent ' + CAST(@ParentID AS nvarchar(20))
            + N' SortID=' + CAST(@SortID AS nvarchar(20));
    END TRY
    BEGIN CATCH
        SET IDENTITY_INSERT dbo.ReportName OFF;
        THROW;
    END CATCH
END
ELSE
BEGIN
    UPDATE dbo.ReportName
    SET Name = @ReportTitle,
        isVisible = 1,
        RefID = @ParentID,
        isRoot = 0
    WHERE ID = @ReportID;
    PRINT N'[SKIP/UPDATE] ReportName ' + CAST(@ReportID AS nvarchar(20)) + N' already exists — refreshed parent/name';
END
GO

-- MenuSub (User Setup > Reports)
IF NOT EXISTS (
    SELECT 1 FROM dbo.MenuSub
    WHERE TypeID = 3 AND MenuID = 1162 AND ISNULL(Deleted, 0) = 0
)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (3, N'Foreign Currency Ledger', 1162, 0, NULL);
ELSE
    UPDATE dbo.MenuSub
    SET Name = N'Foreign Currency Ledger', Deleted = 0
    WHERE TypeID = 3 AND MenuID = 1162;

PRINT N'[OK] MenuSub 1162';
GO

-- UserRights for ALL users (insert missing + enable flags)
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

PRINT N'[OK] UserRights 1162 INSERT missing (rows=' + CAST(@@ROWCOUNT AS nvarchar(20)) + N')';

-- Existing rows often land with all flags = 0 (defaults / prior stub) — force enable
UPDATE dbo.UserRights
SET
    AllowTransaction = 1,
    AllowPrint       = 1,
    AllowExport      = 1,
    AllowExportDOC   = 1,
    AllowExportPDF   = 1
WHERE MenuID = 3
  AND MenuSubID = 1162
  AND (
        ISNULL(AllowTransaction, 0) = 0
     OR ISNULL(AllowPrint, 0) = 0
     OR ISNULL(AllowExport, 0) = 0
     OR ISNULL(AllowExportDOC, 0) = 0
     OR ISNULL(AllowExportPDF, 0) = 0
  );

PRINT N'[OK] UserRights 1162 flags enabled (rows=' + CAST(@@ROWCOUNT AS nvarchar(20)) + N')';
GO

-- Verify
SELECT
    ParentID = P.ID,
    ParentName = P.Name,
    ReportID = R.ID,
    ReportName = R.Name,
    R.SortID,
    R.isVisible,
    MenuSubOk = CASE WHEN EXISTS (
        SELECT 1 FROM dbo.MenuSub M WHERE M.TypeID = 3 AND M.MenuID = 1162 AND ISNULL(M.Deleted,0)=0
    ) THEN N'OK' ELSE N'MISSING' END,
    RightsUsers = (SELECT COUNT(*) FROM dbo.UserRights WHERE MenuID = 3 AND MenuSubID = 1162)
FROM dbo.ReportName R
LEFT JOIN dbo.ReportName P ON P.ID = R.RefID
WHERE R.ID = 1162;
GO

PRINT N'[OK] ForeignCurrencyLedger_ReportMenu done — reopen Reports menu after deploy.';
GO
