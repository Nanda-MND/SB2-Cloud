/*======================================================================
  AccountName.AccountCode — optional display/filter code
  Idempotent. Run on SB2 ERP database.

  Setup Accounts list columns:
    Account Code  = AccountCode
    Code          = Short
  (both visible)

  Note: SortID branch uses dynamic SQL — ListviewItem may not have SortID
  (avoids Msg 207 Invalid column name 'SortID').
======================================================================*/
SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.AccountName', N'AccountCode') IS NULL
BEGIN
    ALTER TABLE dbo.AccountName ADD AccountCode nvarchar(50) NULL;
    PRINT N'[OK] Added AccountName.AccountCode';
END
ELSE
    PRINT N'[SKIP] AccountName.AccountCode already exists';

-- Listview: Account Code column (MenuName = Account shared)
IF NOT EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'Account' AND ColumnName = N'AccountCode')
BEGIN
    IF COL_LENGTH(N'dbo.ListviewItem', N'SortID') IS NOT NULL
    BEGIN
        EXEC sys.sp_executesql N'
            UPDATE dbo.ListviewItem SET SortID = ISNULL(SortID, 0) + 1
            WHERE MenuName = N''Account'' AND ColumnName IN (N''Short'', N''Name'', N''AcctGroup'');

            INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader, SortID)
            VALUES (N''Account'', N''AccountCode'', 140, N''Account Code'', 1);';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
        VALUES (N'Account', N'AccountCode', 140, N'Account Code');
    END
    PRINT N'[OK] ListviewItem Account.AccountCode inserted';
END
ELSE
    PRINT N'[SKIP] ListviewItem Account.AccountCode exists';

-- Account Code column visible
UPDATE dbo.ListviewItem
SET ColumnWidth = 140,
    ColumnHeader = N'Account Code'
WHERE MenuName = N'Account'
  AND ColumnName = N'AccountCode'
  AND (ISNULL(ColumnWidth, 0) < 140 OR ISNULL(ColumnHeader, N'') <> N'Account Code');

IF @@ROWCOUNT > 0
    PRINT N'[OK] ListviewItem Account.AccountCode updated';
ELSE
    PRINT N'[SKIP] ListviewItem Account.AccountCode already OK';

-- Code (Short) column visible — restore if previously hidden (width=0)
IF EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'Account' AND ColumnName = N'Short')
BEGIN
    UPDATE dbo.ListviewItem
    SET ColumnWidth = CASE WHEN ISNULL(ColumnWidth, 0) < 100 THEN 100 ELSE ColumnWidth END,
        ColumnHeader = N'Code'
    WHERE MenuName = N'Account'
      AND ColumnName = N'Short'
      AND (ISNULL(ColumnWidth, 0) < 100 OR ISNULL(ColumnHeader, N'') <> N'Code');

    IF @@ROWCOUNT > 0
        PRINT N'[OK] ListviewItem Account.Short → Code (visible)';
    ELSE
        PRINT N'[SKIP] ListviewItem Account.Short/Code already OK';
END
ELSE
BEGIN
    IF COL_LENGTH(N'dbo.ListviewItem', N'SortID') IS NOT NULL
        EXEC sys.sp_executesql N'
            INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader, SortID)
            VALUES (N''Account'', N''Short'', 100, N''Code'', 2);';
    ELSE
        INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
        VALUES (N'Account', N'Short', 100, N'Code');
    PRINT N'[OK] ListviewItem Account.Short (Code) inserted';
END

PRINT N'[DONE] AccountName_AccountCode';
GO
