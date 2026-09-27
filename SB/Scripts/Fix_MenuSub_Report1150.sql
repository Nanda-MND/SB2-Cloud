/*======================================================================
  Purchase Return REPORTS (1151-1157) — MenuSub + rights fix
  User Setup > Reports and Reports tree children use:
    MenuSub TypeID=3, MenuID = ReportName.ID
    UserRights MenuID=3, MenuSubID = ReportName.ID
    CheckUserRights joins UserRights.MenuSubID = MenuSub.MenuID

  Without MenuSub rows, parent "Purchase Return Reports" shows but
  child reports are hidden and User Setup cannot tick them.

  Run on ERP DB (not master). Idempotent.
======================================================================*/
SET NOCOUNT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database first.', 16, 1);
    SET NOEXEC ON;
END
GO

DECLARE @Reports TABLE (ReportID INT PRIMARY KEY, ReportName NVARCHAR(200));
INSERT INTO @Reports (ReportID, ReportName)
VALUES
    (1151, N'Purchase Return By Each Invoice'),
    (1152, N'Purchase Return By Item Summary'),
    (1153, N'Purchase Return By Item Detail'),
    (1154, N'Return Receive By Each Invoice'),
    (1155, N'Return Receive By Item Summary'),
    (1156, N'Return Receive By Item Detail'),
    (1157, N'Purchase Return Balance');

INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
SELECT 3, R.ReportName, R.ReportID, 0, NULL
FROM @Reports R
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.MenuSub M
    WHERE M.TypeID = 3 AND M.MenuID = R.ReportID AND ISNULL(M.Deleted,0) = 0
);
PRINT 'OK: MenuSub reports 1151-1157 (rows=' + CAST(@@ROWCOUNT AS varchar(20)) + ')';
GO

-- UserRights for users who already have Purchase by Invoice (1013)
INSERT INTO dbo.UserRights (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport, Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT UR.UserID, R.ReportID, 3, UR.AllowTransaction, UR.AllowEdit, UR.AllowDelete, UR.AllowPrint, UR.AllowExport, UR.Reprint, UR.DateChange, UR.AllowExportDOC, UR.AllowExportPDF
FROM dbo.UserRights UR
CROSS JOIN (VALUES (1151),(1152),(1153),(1154),(1155),(1156),(1157)) AS X(ReportID)
JOIN (SELECT ReportID FROM (VALUES (1151),(1152),(1153),(1154),(1155),(1156),(1157)) v(ReportID)) R ON R.ReportID = X.ReportID
WHERE UR.MenuSubID = 1013 AND UR.MenuID = 3 AND ISNULL(UR.AllowTransaction,0) = 1
  AND NOT EXISTS (
        SELECT 1 FROM dbo.UserRights X
        WHERE X.UserID = UR.UserID AND X.MenuSubID = R.ReportID AND X.MenuID = 3
  );
PRINT 'OK: UserRights reports 1151-1157 from 1013';
GO

UPDATE T
SET AllowTransaction = 1
FROM dbo.UserRights T
WHERE T.MenuID = 3
  AND T.MenuSubID IN (1151,1152,1153,1154,1155,1156,1157)
  AND ISNULL(T.AllowTransaction,0) = 0
  AND EXISTS (
        SELECT 1 FROM dbo.UserRights S
        WHERE S.UserID = T.UserID AND S.MenuSubID = 1013 AND S.MenuID = 3
          AND ISNULL(S.AllowTransaction,0) = 1
  );
PRINT 'OK: enabled AllowTransaction for 1151-1157';
GO

SELECT
    dbo.CheckUserRights(1,3,1151,0) AS PurRetInvoice,
    dbo.CheckUserRights(1,3,1157,0) AS PurRetBalance,
    dbo.CheckUserRights(1,3,1013,0) AS PurInvoice;
GO
