/*======================================================================
  Copy UserRights: UserID 3  →  UserID 8

  Replaces all rights for user 8 with an exact copy of user 3.
  Safe to re-run. Run on SB2 in SSMS.
======================================================================*/
USE [SB2];
GO
SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 3)
BEGIN
    PRINT '[FAIL] UserID 3 not found';
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 8)
BEGIN
    PRINT '[FAIL] UserID 8 not found';
    RETURN;
END

DECLARE @FromUser int = 3;
DECLARE @ToUser int = 8;
DECLARE @SrcCnt int, @DstCnt int;

SELECT @SrcCnt = COUNT(*) FROM dbo.UserRights WHERE UserID = @FromUser;
PRINT 'Source UserID ' + CAST(@FromUser AS varchar(10)) + ' rights rows = ' + CAST(@SrcCnt AS varchar(10));

BEGIN TRAN;

-- Remove existing rights for target user
DELETE FROM dbo.UserRights WHERE UserID = @ToUser;
PRINT '[OK] Cleared UserRights for UserID ' + CAST(@ToUser AS varchar(10));

-- Copy every flag from source user
INSERT INTO dbo.UserRights
    (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
     Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT
    @ToUser,
    MenuSubID,
    MenuID,
    AllowTransaction,
    AllowEdit,
    AllowDelete,
    AllowPrint,
    AllowExport,
    Reprint,
    DateChange,
    AllowExportDOC,
    AllowExportPDF
FROM dbo.UserRights
WHERE UserID = @FromUser;

SELECT @DstCnt = COUNT(*) FROM dbo.UserRights WHERE UserID = @ToUser;
PRINT '[OK] Inserted UserRights for UserID ' + CAST(@ToUser AS varchar(10))
    + ' rows = ' + CAST(@DstCnt AS varchar(10));

IF @DstCnt <> @SrcCnt
BEGIN
    ROLLBACK TRAN;
    PRINT '[FAIL] Row count mismatch — rolled back. Src='
        + CAST(@SrcCnt AS varchar(10)) + ' Dst=' + CAST(@DstCnt AS varchar(10));
    RETURN;
END

COMMIT TRAN;
PRINT '[DONE] UserID 8 now matches UserID 3 UserRights';
GO

/* Verify — counts and any flag differences should be empty */
SELECT UserID, Cnt = COUNT(*)
FROM dbo.UserRights
WHERE UserID IN (3, 8)
GROUP BY UserID
ORDER BY UserID;

SELECT
    Diff = N'Missing on User 8',
    S.MenuID, S.MenuSubID,
    S.AllowTransaction, S.AllowEdit, S.AllowDelete, S.AllowPrint, S.AllowExport
FROM dbo.UserRights S
WHERE S.UserID = 3
  AND NOT EXISTS (
        SELECT 1 FROM dbo.UserRights T
        WHERE T.UserID = 8
          AND T.MenuID = S.MenuID
          AND T.MenuSubID = S.MenuSubID
          AND ISNULL(T.AllowTransaction,0) = ISNULL(S.AllowTransaction,0)
          AND ISNULL(T.AllowEdit,0) = ISNULL(S.AllowEdit,0)
          AND ISNULL(T.AllowDelete,0) = ISNULL(S.AllowDelete,0)
          AND ISNULL(T.AllowPrint,0) = ISNULL(S.AllowPrint,0)
          AND ISNULL(T.AllowExport,0) = ISNULL(S.AllowExport,0)
          AND ISNULL(T.Reprint,0) = ISNULL(S.Reprint,0)
          AND ISNULL(T.DateChange,0) = ISNULL(S.DateChange,0)
          AND ISNULL(T.AllowExportDOC,0) = ISNULL(S.AllowExportDOC,0)
          AND ISNULL(T.AllowExportPDF,0) = ISNULL(S.AllowExportPDF,0)
  );

PRINT 'Verify: first grid User 3 and 8 counts equal; second grid empty = OK';
GO
