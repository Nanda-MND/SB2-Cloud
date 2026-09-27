/*======================================================================
  Hotfix: show new Purchase / Manufacture menus
  Root causes on SB2:
    1) MenuSub rows missing for MenuID 30-35 (CheckUserRights joins MenuSub.MenuID)
    2) UserRights for 30/31/35 never created (old script used wrong MenuID=5)
    3) Some UserRights rows exist with AllowTransaction=0 (hides menu)

  Run on ERP DB (not master). Idempotent.
======================================================================*/
SET NOCOUNT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database first.', 16, 1);
    SET NOEXEC ON;
END
GO

/* 1) MenuSub — required by CheckUserRights */
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 30 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID) VALUES (2, N'Return Stock', 30, 0, 5);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 31 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID) VALUES (2, N'Get Stock', 31, 0, 5);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 32 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID) VALUES (2, N'Return Receive', 32, 0, 2);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 33 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID) VALUES (2, N'Goods Issue', 33, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 34 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID) VALUES (2, N'Goods Receive', 34, 0, 2);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 35 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID) VALUES (2, N'Goods Receive (Manu)', 35, 0, 5);
PRINT 'OK: MenuSub 30-35';
GO

/* 2) Insert missing UserRights (Transactions module MenuID = 2) */
INSERT INTO dbo.UserRights (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport, Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT UR.UserID, M.NewSub, 2, UR.AllowTransaction, UR.AllowEdit, UR.AllowDelete, UR.AllowPrint, UR.AllowExport, UR.Reprint, UR.DateChange, UR.AllowExportDOC, UR.AllowExportPDF
FROM dbo.UserRights UR
CROSS JOIN (VALUES
    (32, 7),   -- Return Receive  <- Purchase Return
    (34, 6),   -- Goods Receive   <- Shipments
    (30, 24),  -- Return Stock    <- Raw Issue
    (31, 24),  -- Get Stock       <- Raw Issue
    (33, 3)    -- Goods Issue     <- Sale Return
) M(NewSub, FromSub)
WHERE UR.MenuSubID = M.FromSub AND UR.MenuID = 2 AND ISNULL(UR.AllowTransaction,0) = 1
  AND NOT EXISTS (
        SELECT 1 FROM dbo.UserRights X
        WHERE X.UserID = UR.UserID AND X.MenuSubID = M.NewSub AND X.MenuID = 2
  );
PRINT 'OK: UserRights insert 30-35';
GO

/* 3) Enable any existing zero-rights rows for users who already have the source menu */
UPDATE T
SET
    AllowTransaction = S.AllowTransaction,
    AllowEdit        = S.AllowEdit,
    AllowDelete      = S.AllowDelete,
    AllowPrint       = S.AllowPrint,
    AllowExport      = S.AllowExport,
    Reprint          = S.Reprint,
    DateChange       = S.DateChange,
    AllowExportDOC   = S.AllowExportDOC,
    AllowExportPDF   = S.AllowExportPDF
FROM dbo.UserRights T
JOIN (VALUES
    (32, 7), (34, 6), (30, 24), (31, 24), (33, 3)
) M(NewSub, FromSub) ON T.MenuSubID = M.NewSub AND T.MenuID = 2
JOIN dbo.UserRights S ON S.UserID = T.UserID AND S.MenuSubID = M.FromSub AND S.MenuID = 2
WHERE ISNULL(S.AllowTransaction,0) = 1
  AND ISNULL(T.AllowTransaction,0) = 0;
PRINT 'OK: UserRights enable AllowTransaction for 30-35';
GO

/* 4) Remove duplicate disabled rows when an enabled row already exists */
DELETE D
FROM dbo.UserRights D
WHERE D.MenuID = 2
  AND D.MenuSubID IN (30,31,32,33,34)
  AND ISNULL(D.AllowTransaction,0) = 0
  AND EXISTS (
        SELECT 1 FROM dbo.UserRights E
        WHERE E.UserID = D.UserID AND E.MenuID = 2 AND E.MenuSubID = D.MenuSubID
          AND ISNULL(E.AllowTransaction,0) = 1
  );
PRINT 'OK: removed duplicate disabled UserRights';
GO

UPDATE dbo.UserRights
SET AllowTransaction = 0, AllowEdit = 0, AllowDelete = 0, AllowPrint = 0, AllowExport = 0
WHERE MenuID = 2 AND MenuSubID = 35;
PRINT 'OK: Goods Receive (Manu) menu 35 disabled';
GO

SELECT
    dbo.CheckUserRights(1,2,7,2)  AS PurReturn,
    dbo.CheckUserRights(1,2,32,2) AS ReturnReceive,
    dbo.CheckUserRights(1,2,34,2) AS GoodsReceive,
    dbo.CheckUserRights(1,2,24,5) AS RawIssue,
    dbo.CheckUserRights(1,2,25,5) AS FinishGoods,
    dbo.CheckUserRights(1,2,30,5) AS ReturnStock,
    dbo.CheckUserRights(1,2,31,5) AS GetStock,
    dbo.CheckUserRights(1,2,35,5) AS GoodsReceiveManu;
GO
