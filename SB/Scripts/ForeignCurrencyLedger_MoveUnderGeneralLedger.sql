/*
  Move 1162 under General Ledger folder + verify parent.
  Also prints sibling reports so you can confirm the folder.
*/
SET NOCOUNT ON;

DECLARE @ParentID int = NULL;
DECLARE @SortID int = 1;

-- Root folder (exact / like), ignore isVisible
SELECT TOP (1) @ParentID = ID
FROM dbo.ReportName
WHERE ISNULL(isRoot, 0) = 1
  AND LTRIM(RTRIM(Name)) IN (N'General Ledger', N'GeneralLedger')
ORDER BY SortID, ID;

IF @ParentID IS NULL
    SELECT TOP (1) @ParentID = ID
    FROM dbo.ReportName
    WHERE ISNULL(isRoot, 0) = 1
      AND Name LIKE N'%General Ledger%'
      AND Name NOT LIKE N'%Accounting%'
    ORDER BY SortID, ID;

-- Parent shared by GL Detail / Summary / Account Detail / Bank Statement
IF @ParentID IS NULL
    SELECT TOP (1) @ParentID = RefID
    FROM dbo.ReportName
    WHERE ISNULL(isRoot, 0) = 0
      AND ISNULL(RefID, 0) > 0
      AND (
            Name IN (N'Account Detail', N'General Ledger Detail', N'General Ledger Summary',
                     N'Cash/ Bank Statement', N'Cash/Bank Statement', N'Bank Balance')
         OR ID IN (1068, 1142, 1130, 1101, 1069, 1143)
          )
    ORDER BY CASE
        WHEN Name = N'General Ledger Detail' THEN 1
        WHEN Name = N'Account Detail' THEN 2
        WHEN ID = 1068 THEN 3
        ELSE 9 END;

IF @ParentID IS NULL
BEGIN
    SELECT ID, Name, isRoot, RefID, isVisible, SortID
    FROM dbo.ReportName
    WHERE Name LIKE N'%General Ledger%' OR Name LIKE N'%Account Detail%' OR Name LIKE N'%Bank Statement%'
    ORDER BY isRoot DESC, RefID, SortID;
    RAISERROR(N'General Ledger folder not found — see result set above.', 16, 1);
    RETURN;
END

SELECT @SortID = ISNULL(MAX(SortID), 0) + 1
FROM dbo.ReportName
WHERE RefID = @ParentID AND ISNULL(isRoot, 0) = 0 AND ID <> 1162;

UPDATE dbo.ReportName
SET RefID = @ParentID, isRoot = 0, isVisible = 1,
    Name = N'Foreign Currency Ledger', SortID = @SortID
WHERE ID = 1162;

SELECT N'--- Parent ---' AS Info, P.ID, P.Name, P.isRoot
FROM dbo.ReportName P WHERE P.ID = @ParentID;

SELECT N'--- Children (incl 1162) ---' AS Info, R.ID, R.Name, R.SortID, R.RefID
FROM dbo.ReportName R
WHERE R.RefID = @ParentID AND ISNULL(R.isRoot, 0) = 0
ORDER BY R.SortID, R.ID;

PRINT N'[OK] Moved 1162 — close/reopen Reports.';
GO
