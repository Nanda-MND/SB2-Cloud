/*
  Account Setup — use AccountName.AccountCode (existing column used by Opening report).
  ListviewItem: Account Code column before Short.

  Deploy on SB1. Restart app after deploy (ReferenceDataCache).
*/

SET NOCOUNT ON;

-- 1) Ensure AccountCode column exists
IF COL_LENGTH(N'dbo.AccountName', N'AccountCode') IS NULL
BEGIN
    EXEC(N'ALTER TABLE dbo.AccountName ADD AccountCode nvarchar(50) NULL;');
    PRINT 'Added AccountName.AccountCode';
END
ELSE
    PRINT 'AccountName.AccountCode already exists';
GO

-- If earlier deploy created empty AcctCode, copy into AccountCode where empty
IF COL_LENGTH(N'dbo.AccountName', N'AcctCode') IS NOT NULL
   AND COL_LENGTH(N'dbo.AccountName', N'AccountCode') IS NOT NULL
BEGIN
    EXEC(N'
        UPDATE dbo.AccountName
        SET AccountCode = AcctCode
        WHERE ISNULL(AccountCode, N'''') = N''''
          AND ISNULL(AcctCode, N'''') <> N'''';
    ');
    PRINT 'Synced AcctCode → AccountCode where AccountCode was empty';
END
GO

SELECT
    HasAccountCode = CASE WHEN COL_LENGTH(N'dbo.AccountName', N'AccountCode') IS NULL THEN 0 ELSE 1 END,
    FilledCnt = (SELECT COUNT(*) FROM dbo.AccountName WHERE ISNULL(AccountCode, N'') <> N'');
GO

-- 2) ListviewItem: AccountCode before Short (header = Account Code)
IF OBJECT_ID(N'dbo.ListviewItem', N'U') IS NOT NULL
BEGIN
    -- Rename legacy AcctCode list column → AccountCode
    IF EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'Account' AND ColumnName = N'AcctCode')
       AND NOT EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'Account' AND ColumnName = N'AccountCode')
    BEGIN
        UPDATE dbo.ListviewItem
        SET ColumnName = N'AccountCode',
            ColumnHeader = N'Account Code',
            ColumnWidth = 120
        WHERE MenuName = N'Account' AND ColumnName = N'AcctCode';
        PRINT 'Renamed ListviewItem AcctCode → AccountCode';
    END

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.ListviewItem
        WHERE MenuName = N'Account' AND ColumnName = N'AccountCode'
    )
    BEGIN
        INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
        VALUES (N'Account', N'AccountCode', 120, N'Account Code');
        PRINT 'Inserted ListviewItem Account / AccountCode';
    END
    ELSE
    BEGIN
        UPDATE dbo.ListviewItem
        SET ColumnHeader = N'Account Code',
            ColumnWidth = 120
        WHERE MenuName = N'Account' AND ColumnName = N'AccountCode';
    END

    -- Drop duplicate AcctCode row if both exist
    DELETE FROM dbo.ListviewItem
    WHERE MenuName = N'Account' AND ColumnName = N'AcctCode';

    -- Rebuild order: AccountCode, Short, Name, AcctGroup, then others
    IF OBJECT_ID(N'tempdb..#AcctCols') IS NOT NULL DROP TABLE #AcctCols;
    CREATE TABLE #AcctCols
    (
        SortOrd int NOT NULL,
        ColumnName nvarchar(100) NOT NULL,
        ColumnWidth int NULL,
        ColumnHeader nvarchar(100) NULL
    );

    INSERT INTO #AcctCols (SortOrd, ColumnName, ColumnWidth, ColumnHeader)
    SELECT
        SortOrd =
            CASE L.ColumnName
                WHEN N'AccountCode' THEN 1
                WHEN N'Short' THEN 2
                WHEN N'Name' THEN 3
                WHEN N'AcctGroup' THEN 4
                ELSE 100 + L.ID
            END,
        L.ColumnName,
        L.ColumnWidth,
        L.ColumnHeader
    FROM dbo.ListviewItem L
    WHERE L.MenuName = N'Account';

    DELETE FROM dbo.ListviewItem WHERE MenuName = N'Account';

    INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    SELECT N'Account', ColumnName, ColumnWidth, ColumnHeader
    FROM #AcctCols
    ORDER BY SortOrd, ColumnName;

    DROP TABLE #AcctCols;

    SELECT ID, MenuName, ColumnName, ColumnWidth, ColumnHeader
    FROM dbo.ListviewItem
    WHERE MenuName = N'Account'
    ORDER BY ID;
END
GO
