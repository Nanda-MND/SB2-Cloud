/*
  AccountName.ID — unused scan (Tables + SP + TVF + SVF) then soft-delete

  MAIN RESULT (default): only these grids in SSMS Results
    1) SUMMARY
    2) UNUSED AccountName.ID   ← ဒီ grid ကြည့် (Deleted=1 မပါ)
    3) UNUSED AcctGroup
    4) UNUSED AcctSubGroup

  Soft-delete = Deleted = 1. Hard DELETE မလုပ်။

  HOW TO RUN (SB2)
  ----------------
  1) Backup DB
  2) Whole script F5  (@DoDelete = 0)
  3) Results pane → "UNUSED AccountName" grid ကြည့်
  4) OK မှ @DoDelete = 1 → ပြန် F5

  Optional:
    @ShowScanDetails = 1  → table/module diagnostic grids
    @ScanTrialBalance = 1 → also mark TB activity (adds TB result noise)
*/
SET NOCOUNT ON;

IF OBJECT_ID(N'tempdb..#AcctCOA_Protected') IS NOT NULL DROP TABLE #AcctCOA_Protected;
IF OBJECT_ID(N'tempdb..#AcctCOA_Used') IS NOT NULL DROP TABLE #AcctCOA_Used;
IF OBJECT_ID(N'tempdb..#AcctCOA_UnusedAccount') IS NOT NULL DROP TABLE #AcctCOA_UnusedAccount;
IF OBJECT_ID(N'tempdb..#AcctCOA_UnusedGroup') IS NOT NULL DROP TABLE #AcctCOA_UnusedGroup;
IF OBJECT_ID(N'tempdb..#AcctCOA_UnusedSubGroup') IS NOT NULL DROP TABLE #AcctCOA_UnusedSubGroup;
IF OBJECT_ID(N'tempdb..#AcctCOA_SpHit') IS NOT NULL DROP TABLE #AcctCOA_SpHit;
IF OBJECT_ID(N'tempdb..#AcctCOA_SpDef') IS NOT NULL DROP TABLE #AcctCOA_SpDef;
IF OBJECT_ID(N'tempdb..#AcctCOA_Candidate') IS NOT NULL DROP TABLE #AcctCOA_Candidate;
IF OBJECT_ID(N'tempdb..#AcctCOA_ColScan') IS NOT NULL DROP TABLE #AcctCOA_ColScan;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DoDelete         bit = 0;  -- 0 = preview, 1 = soft-delete
DECLARE @ShowScanDetails  bit = 0;  -- 1 = show table/module diagnostic grids
DECLARE @ScanTrialBalance bit = 0;  -- 0 default (TB EXEC floods Results pane)
DECLARE @FromDate         datetime = '2000-01-01';
DECLARE @ToDate           datetime = CONVERT(date, GETDATE());
DECLARE @ScanUserID       int = -99771;

/* ============================================================
   Protected AccountName.ID (never soft-delete)
   ============================================================ */
CREATE TABLE #AcctCOA_Protected (AcctID int NOT NULL PRIMARY KEY);

INSERT INTO #AcctCOA_Protected (AcctID) VALUES
    (26), (112), (113), (114), (198), (224), (288), (289),
    (436), (1452), (1482), (1491), (1492), (1493), (2500), (2501);

INSERT INTO #AcctCOA_Protected (AcctID)
SELECT AN.ID
FROM dbo.AccountName AN
WHERE UPPER(ISNULL(AN.Short, N'')) IN
(
    N'AYARMMQR', N'MMQR', N'CASH', N'CIH',
    N'AP', N'AR', N'CREDITOR', N'DEBTOR'
)
  AND NOT EXISTS (SELECT 1 FROM #AcctCOA_Protected P WHERE P.AcctID = AN.ID);

INSERT INTO #AcctCOA_Protected (AcctID)
SELECT AN.ID
FROM dbo.AccountName AN
WHERE AN.SysAcctID IN (2, 6)
  AND NOT EXISTS (SELECT 1 FROM #AcctCOA_Protected P WHERE P.AcctID = AN.ID);

/* ============================================================
   A) Tables — AccountName-like FK columns
   ============================================================ */
CREATE TABLE #AcctCOA_Used
(
    AcctID    int NOT NULL,
    SourceTbl sysname NOT NULL,
    SourceCol sysname NOT NULL
);

CREATE TABLE #AcctCOA_ColScan
(
    FullName nvarchar(512) NOT NULL,
    TblName  sysname NOT NULL,
    ColName  sysname NOT NULL
);

INSERT INTO #AcctCOA_ColScan (FullName, TblName, ColName)
SELECT
    FullName = QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name),
    TblName  = t.name,
    ColName  = c.name
FROM sys.tables t
INNER JOIN sys.columns c ON c.object_id = t.object_id
INNER JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND t.name NOT IN (N'AccountName', N'GeneralLedgerDetail')
  AND ty.name IN (N'int', N'bigint', N'smallint', N'tinyint', N'numeric', N'decimal')
  AND (
         c.name LIKE N'%AccountID'
      OR c.name IN (N'FromAcctID', N'ToAcctID', N'LedgerID', N'AcctID', N'LedgerAccountID')
      );

IF @ShowScanDetails = 1
BEGIN
    PRINT N'=== Table columns scanned ===';
    SELECT FullName, ColName FROM #AcctCOA_ColScan ORDER BY FullName, ColName;
END

DECLARE @full nvarchar(512), @tbl sysname, @col sysname, @piece nvarchar(max);

DECLARE src CURSOR LOCAL FAST_FORWARD FOR
SELECT FullName, TblName, ColName FROM #AcctCOA_ColScan;

OPEN src;
FETCH NEXT FROM src INTO @full, @tbl, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(@full, N'U') IS NOT NULL AND COL_LENGTH(@full, @col) IS NOT NULL
    BEGIN
        SET @piece = N'
INSERT INTO #AcctCOA_Used (AcctID, SourceTbl, SourceCol)
SELECT DISTINCT CAST(' + QUOTENAME(@col) + N' AS int),
       N''' + REPLACE(@tbl, N'''', N'''''') + N''',
       N''' + REPLACE(@col, N'''', N'''''') + N'''
FROM ' + @full + N'
WHERE ' + QUOTENAME(@col) + N' IS NOT NULL
  AND CAST(' + QUOTENAME(@col) + N' AS int) > 0;';
        BEGIN TRY
            EXEC sp_executesql @piece;
        END TRY
        BEGIN CATCH
            PRINT N'Table scan SKIP ' + @full + N'.' + @col + N': ' + ERROR_MESSAGE();
        END CATCH
    END
    FETCH NEXT FROM src INTO @full, @tbl, @col;
END
CLOSE src;
DEALLOCATE src;

/* ============================================================
   B) ALL SP / TVF / SVF — hardcoded IDs (table-unused candidates only)
   ============================================================ */
CREATE TABLE #AcctCOA_SpDef
(
    ObjectName sysname NOT NULL PRIMARY KEY,
    ObjType    char(2) NOT NULL,
    Def        nvarchar(max) NULL
);

INSERT INTO #AcctCOA_SpDef (ObjectName, ObjType, Def)
SELECT
    ObjectName = QUOTENAME(OBJECT_SCHEMA_NAME(m.object_id)) + N'.' + QUOTENAME(OBJECT_NAME(m.object_id)),
    ObjType    = o.type,
    Def        = m.definition
FROM sys.sql_modules m
INNER JOIN sys.objects o ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN (N'P', N'FN', N'IF', N'TF', N'FT');

CREATE TABLE #AcctCOA_Candidate
(
    AcctID int NOT NULL PRIMARY KEY,
    Short  nvarchar(100) NULL,
    IdTxt  varchar(20) NOT NULL
);

-- Candidates: active AccountName only (soft-deleted already out)
INSERT INTO #AcctCOA_Candidate (AcctID, Short, IdTxt)
SELECT AN.ID, AN.Short, CAST(AN.ID AS varchar(20))
FROM dbo.AccountName AN
WHERE ISNULL(AN.Deleted, 0) <> 1
  AND NOT EXISTS (SELECT 1 FROM #AcctCOA_Protected P WHERE P.AcctID = AN.ID)
  AND NOT EXISTS (SELECT 1 FROM #AcctCOA_Used U WHERE U.AcctID = AN.ID);

CREATE TABLE #AcctCOA_SpHit
(
    ObjectName sysname NOT NULL,
    ObjType    char(2) NOT NULL,
    AcctID     int NOT NULL,
    MatchHint  nvarchar(200) NULL
);

-- Strict account-keyword literals only (no bare IN-list — avoids PaymentID=1,2,5 false hits)
INSERT INTO #AcctCOA_SpHit (ObjectName, ObjType, AcctID, MatchHint)
SELECT D.ObjectName, D.ObjType, C.AcctID, N'Account/Ledger literal'
FROM #AcctCOA_SpDef D
CROSS JOIN #AcctCOA_Candidate C
WHERE D.Def IS NOT NULL
  AND CHARINDEX(C.IdTxt, D.Def) > 0
  AND (
         D.Def LIKE N'%AccountID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%AccountID% = ' + C.IdTxt + N'%'
      OR D.Def LIKE N'%DetailAccountID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%DetailAccountID% = ' + C.IdTxt + N'%'
      OR D.Def LIKE N'%FromAcctID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%FromAcctID% = ' + C.IdTxt + N'%'
      OR D.Def LIKE N'%ToAcctID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%ToAcctID% = ' + C.IdTxt + N'%'
      OR D.Def LIKE N'%LedgerID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%LedgerID% = ' + C.IdTxt + N'%'
      OR D.Def LIKE N'%LedgerAccountID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%LedgerAccountID% = ' + C.IdTxt + N'%'
      OR D.Def LIKE N'%AcctID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%AcctID% = ' + C.IdTxt + N'%'
      OR D.Def LIKE N'%AN.ID%=' + C.IdTxt + N'%'
      OR D.Def LIKE N'%AN.ID% = ' + C.IdTxt + N'%'
  );

INSERT INTO #AcctCOA_SpHit (ObjectName, ObjType, AcctID, MatchHint)
SELECT D.ObjectName, D.ObjType, C.AcctID, N'Short literal'
FROM #AcctCOA_SpDef D
INNER JOIN #AcctCOA_Candidate C ON LEN(ISNULL(C.Short, N'')) >= 2
WHERE D.Def IS NOT NULL
  AND CHARINDEX(C.Short, D.Def) > 0
  AND (
         D.Def LIKE N'%Short%=''' + REPLACE(C.Short, N'''', N'''''') + N'''%'
      OR D.Def LIKE N'%Short% = ''' + REPLACE(C.Short, N'''', N'''''') + N'''%'
      OR D.Def LIKE N'%Short%=N''' + REPLACE(C.Short, N'''', N'''''') + N'''%'
      OR D.Def LIKE N'%Short% = N''' + REPLACE(C.Short, N'''', N'''''') + N'''%'
  )
  AND NOT EXISTS
  (
      SELECT 1 FROM #AcctCOA_SpHit H
      WHERE H.ObjectName = D.ObjectName AND H.AcctID = C.AcctID
  );

INSERT INTO #AcctCOA_Used (AcctID, SourceTbl, SourceCol)
SELECT DISTINCT H.AcctID, H.ObjectName, N'MODULE_' + H.ObjType
FROM #AcctCOA_SpHit H
WHERE NOT EXISTS
(
    SELECT 1 FROM #AcctCOA_Used U
    WHERE U.AcctID = H.AcctID AND U.SourceTbl = H.ObjectName
);

INSERT INTO #AcctCOA_Protected (AcctID)
SELECT DISTINCT H.AcctID
FROM #AcctCOA_SpHit H
WHERE NOT EXISTS (SELECT 1 FROM #AcctCOA_Protected P WHERE P.AcctID = H.AcctID);

IF @ShowScanDetails = 1
BEGIN
    PRINT N'=== SQL modules ===';
    SELECT
        ObjType,
        TypeName = CASE ObjType
            WHEN N'P' THEN N'SP' WHEN N'FN' THEN N'SVF'
            WHEN N'IF' THEN N'TVF-inline' WHEN N'TF' THEN N'TVF-multi'
            WHEN N'FT' THEN N'TVF-CLR' ELSE ObjType END,
        ModuleCount = COUNT(*),
        WithDefinition = SUM(CASE WHEN Def IS NOT NULL THEN 1 ELSE 0 END)
    FROM #AcctCOA_SpDef
    GROUP BY ObjType
    ORDER BY ObjType;

    PRINT N'=== Module hardcoded hits ===';
    SELECT H.ObjectName, H.AcctID, AN.Short, AN.Name, H.MatchHint
    FROM #AcctCOA_SpHit H
    LEFT JOIN dbo.AccountName AN ON AN.ID = H.AcctID
    ORDER BY H.ObjectName, H.AcctID;
END

/* ============================================================
   C) TrialBalance (optional — off by default; floods Results)
   ============================================================ */
IF @ScanTrialBalance = 1
   AND OBJECT_ID(N'dbo.TrialBalance', N'P') IS NOT NULL
   AND OBJECT_ID(N'dbo.GeneralLedgerDetail', N'U') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC dbo.TrialBalance
            @FromDate = @FromDate,
            @ToDate   = @ToDate,
            @UserID   = @ScanUserID;

        SET @piece = N'
INSERT INTO #AcctCOA_Used (AcctID, SourceTbl, SourceCol)
SELECT DISTINCT AN.ID, N''TrialBalance'', N''LedgerName''
FROM dbo.GeneralLedgerDetail G
INNER JOIN dbo.AccountName AN ON AN.Name = G.LedgerName
WHERE G.UserID = @uid
  AND ISNULL(AN.Deleted, 0) <> 1
  AND (ISNULL(G.Debit, 0) <> 0 OR ISNULL(G.Credit, 0) <> 0'
            + CASE WHEN COL_LENGTH(N'dbo.GeneralLedgerDetail', N'Balance') IS NOT NULL
                   THEN N' OR ISNULL(G.Balance, 0) <> 0' ELSE N'' END
            + N')
  AND NOT EXISTS (
        SELECT 1 FROM #AcctCOA_Used U
        WHERE U.AcctID = AN.ID AND U.SourceTbl = N''TrialBalance'');';
        EXEC sp_executesql @piece, N'@uid int', @uid = @ScanUserID;
        PRINT N'TrialBalance scan OK.';
    END TRY
    BEGIN CATCH
        PRINT N'TrialBalance scan SKIPPED: ' + ERROR_MESSAGE();
    END CATCH
END

/* ============================================================
   Unused lists — ACTIVE only (Deleted=1 excluded)
   ============================================================ */
SELECT
    AN.ID,
    AN.Short,
    AN.Name,
    AN.GroupID,
    GroupShort = AG.Short,
    GroupName  = AG.Name,
    AN.SysAcctID
INTO #AcctCOA_UnusedAccount
FROM dbo.AccountName AN
LEFT JOIN dbo.AcctGroup AG ON AG.ID = AN.GroupID
WHERE ISNULL(AN.Deleted, 0) <> 1          -- soft-deleted မပါ
  AND NOT EXISTS (SELECT 1 FROM #AcctCOA_Protected P WHERE P.AcctID = AN.ID)
  AND NOT EXISTS (SELECT 1 FROM #AcctCOA_Used U WHERE U.AcctID = AN.ID);

SELECT
    AG.ID,
    AG.Short,
    AG.Name,
    AG.SubGroupID,
    SubGroupShort = SG.Short,
    SubGroupName  = SG.Name
INTO #AcctCOA_UnusedGroup
FROM dbo.AcctGroup AG
LEFT JOIN dbo.AcctSubGroup SG ON SG.ID = AG.SubGroupID
WHERE ISNULL(AG.Deleted, 0) <> 1
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.AccountName AN
      WHERE AN.GroupID = AG.ID
        AND ISNULL(AN.Deleted, 0) <> 1
        AND AN.ID NOT IN (SELECT ID FROM #AcctCOA_UnusedAccount)
  );

SELECT
    SG.ID,
    SG.Short,
    SG.Name,
    SG.MainGroupID,
    MainGroupName = MG.Name
INTO #AcctCOA_UnusedSubGroup
FROM dbo.AcctSubGroup SG
LEFT JOIN dbo.AcctMainGroup MG ON MG.ID = SG.MainGroupID
WHERE ISNULL(SG.Deleted, 0) <> 1
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.AcctGroup AG
      WHERE AG.SubGroupID = SG.ID
        AND ISNULL(AG.Deleted, 0) <> 1
        AND AG.ID NOT IN (SELECT ID FROM #AcctCOA_UnusedGroup)
  );

/* ============================================================
   ★ MAIN RESULTS — ကြည့်ရမယ့် grids (၄ ခုသာ)
   ============================================================ */

-- Grid 1
SELECT
    WhatToLookAt          = N'>>> Grid 2 = UNUSED AccountName.ID (soft-deleted မပါ) <<<',
    ActiveAccountName     = (SELECT COUNT(*) FROM dbo.AccountName WHERE ISNULL(Deleted, 0) <> 1),
    UsedDistinctAccounts  = (SELECT COUNT(DISTINCT AcctID) FROM #AcctCOA_Used),
    ProtectedCount        = (SELECT COUNT(*) FROM #AcctCOA_Protected),
    ModulesScanned        = (SELECT COUNT(*) FROM #AcctCOA_SpDef),
    ModuleHardcodedHits   = (SELECT COUNT(*) FROM #AcctCOA_SpHit),
    UnusedAccountCount    = (SELECT COUNT(*) FROM #AcctCOA_UnusedAccount),
    UnusedGroupCount      = (SELECT COUNT(*) FROM #AcctCOA_UnusedGroup),
    UnusedSubGroupCount   = (SELECT COUNT(*) FROM #AcctCOA_UnusedSubGroup);

-- Grid 2  ★★★  UNUSED AccountName.ID  ★★★
SELECT
    UnusedID   = U.ID,
    U.Short,
    U.Name,
    U.GroupID,
    U.GroupShort,
    U.GroupName,
    U.SysAcctID
FROM #AcctCOA_UnusedAccount U
ORDER BY U.GroupName, U.Short, U.Name;

-- Grid 3
SELECT
    UnusedGroupID = U.ID,
    U.Short,
    U.Name,
    U.SubGroupID,
    U.SubGroupShort,
    U.SubGroupName
FROM #AcctCOA_UnusedGroup U
ORDER BY U.SubGroupName, U.Short, U.Name;

-- Grid 4
SELECT
    UnusedSubGroupID = U.ID,
    U.Short,
    U.Name,
    U.MainGroupID,
    U.MainGroupName
FROM #AcctCOA_UnusedSubGroup U
ORDER BY U.MainGroupName, U.Short, U.Name;

PRINT N'';
PRINT N'Results: Grid1=SUMMARY | Grid2=UNUSED AccountName.ID | Grid3=Group | Grid4=SubGroup';
PRINT N'(Deleted=1 rows are excluded from all unused lists.)';

/* ============================================================
   Soft-delete
   ============================================================ */
IF @DoDelete = 0
BEGIN
    PRINT N'PREVIEW ONLY — set @DoDelete = 1 and re-run to soft-delete.';
END
ELSE
BEGIN
    BEGIN TRAN;

    UPDATE AN
    SET Deleted = 1
    FROM dbo.AccountName AN
    INNER JOIN #AcctCOA_UnusedAccount U ON U.ID = AN.ID
    WHERE ISNULL(AN.Deleted, 0) <> 1;

    DECLARE @acctDel int = @@ROWCOUNT;

    UPDATE AG
    SET Deleted = 1
    FROM dbo.AcctGroup AG
    INNER JOIN #AcctCOA_UnusedGroup U ON U.ID = AG.ID
    WHERE ISNULL(AG.Deleted, 0) <> 1
      AND NOT EXISTS
      (
          SELECT 1 FROM dbo.AccountName AN
          WHERE AN.GroupID = AG.ID AND ISNULL(AN.Deleted, 0) <> 1
      );

    DECLARE @grpDel int = @@ROWCOUNT;

    UPDATE SG
    SET Deleted = 1
    FROM dbo.AcctSubGroup SG
    INNER JOIN #AcctCOA_UnusedSubGroup U ON U.ID = SG.ID
    WHERE ISNULL(SG.Deleted, 0) <> 1
      AND NOT EXISTS
      (
          SELECT 1 FROM dbo.AcctGroup AG
          WHERE AG.SubGroupID = SG.ID AND ISNULL(AG.Deleted, 0) <> 1
      );

    DECLARE @subDel int = @@ROWCOUNT;

    COMMIT TRAN;

    SELECT
        SoftDeleted_AccountName  = @acctDel,
        SoftDeleted_AcctGroup    = @grpDel,
        SoftDeleted_AcctSubGroup = @subDel;

    PRINT N'SOFT-DELETE DONE.';
END
GO
