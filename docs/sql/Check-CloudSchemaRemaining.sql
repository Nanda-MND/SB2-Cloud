/*
  Cloud — ကျန်သေးတဲ့ schema/SP/FN စစ်ရန်
  Run on: db_abbe78_warehouse (CLOUD)

  Status:
    OK       = ရှိပြီး Local ရည်ညွှန်းရက်နဲ့ နီး / ရောက်ပြီး
    MISSING  = မရှိ → script တင်ရမယ်
    OLDER    = ရှိပေမယ့် ဟောင်း → Local ဗားရှင်း ပြန်တင်

  Restore approx: 2026-06-22
*/

SET NOCOUNT ON;

PRINT '=== ' + DB_NAME() + ' | ' + CONVERT(varchar(19), SYSDATETIME(), 120) + ' ===';

------------------------------------------------------------------------------
-- 1) Columns
------------------------------------------------------------------------------
PRINT '=== 1. Columns ===';
;WITH want AS (
    SELECT * FROM (VALUES
        (N'SaleHead',            N'IsBankCharges'),
        (N'SaleHead',            N'AddAmount'),
        (N'Customer',            N'TransportCharges'),
        (N'AccountName',         N'AccountCode'),
        (N'AcctGroup',           N'GroupCode'),
        (N'AcctSubGroup',        N'SubGroupCode'),
        (N'IncomeExpenseHead',   N'PrintCheque')
    ) v(TableName, ColumnName)
)
SELECT
    w.TableName,
    w.ColumnName,
    CASE WHEN COL_LENGTH(N'dbo.' + w.TableName, w.ColumnName) IS NULL
         THEN N'MISSING' ELSE N'OK' END AS Status
FROM want w
ORDER BY Status DESC, w.TableName, w.ColumnName;

------------------------------------------------------------------------------
-- 2) Routines
------------------------------------------------------------------------------
PRINT '=== 2. Routines ===';
;WITH want AS (
    SELECT * FROM (VALUES
        (N'fn_AccountInFilter',           N'AccountFilter_Helper.sql',                         '2026-09-10'),
        (N'GeneralLedgerSummary',         N'GeneralLedgerSummary.sql',                         '2026-09-10'),
        (N'GeneralLedgerDetailReport',    N'GeneralLedgerDetailReport_ExcludeAddAmount.sql',   '2026-09-10'),
        (N'GeneralLedgerDetailReport_ND', N'GL_AccountMultiFilter_Patch.sql',                  '2026-09-10'),
        (N'CustomerBalanceDetail',        N'CustomerBalanceDetail_IncludeAddAmount.sql',       '2026-09-10'),
        (N'SaleHistory',                  N'SaleHistory_AddCharges.sql + FilterAccountPayment','2026-09-01'),
        (N'CashbookHistory',              N'CashbookHistory_PrintCheque.sql',                  '2026-08-04'),
        (N'TitanBalanceDetail',           N'TitanBalanceDetail_FixOpening.sql',                '2026-08-08'),
        (N'SaleAdvBalanceCheck',          N'SaleAdvBalanceCheck.sql',                          '2026-08-01'),
        -- Base GetNumToMyan is NOT in Fix_GetNumToMyan.sql (digit map only).
        -- Flag OLDER only if missing; date check skipped via LocalMinDate = 1900-01-01.
        (N'GetNumToMyan',                 N'(base — no deploy in Fix script)',               '1900-01-01'),
        (N'GetNumToMyan1',                N'Fix_GetNumToMyan.sql',                             '2026-08-04'),
        (N'GetNumToMyan2',                N'Fix_GetNumToMyan.sql',                             '2026-08-04'),
        (N'CustSupHistory',               N'CustSupHistory_Fix.sql',                           '2026-08-01')
    ) v(ObjectName, DeployScript, LocalMinDate)
)
SELECT
    w.ObjectName,
    w.DeployScript,
    CASE
        WHEN o.object_id IS NULL THEN N'MISSING'
        WHEN CAST(o.modify_date AS date) < CONVERT(date, w.LocalMinDate) THEN N'OLDER'
        ELSE N'OK'
    END AS Status,
    o.type_desc,
    o.modify_date AS CloudModifyDate,
    CONVERT(date, w.LocalMinDate) AS LocalMinDate
FROM want w
LEFT JOIN sys.objects o ON o.object_id = OBJECT_ID(N'dbo.' + w.ObjectName)
ORDER BY
    CASE
        WHEN o.object_id IS NULL THEN 0
        WHEN CAST(o.modify_date AS date) < CONVERT(date, w.LocalMinDate) THEN 1
        ELSE 2
    END,
    w.ObjectName;

------------------------------------------------------------------------------
-- 3) Report register
------------------------------------------------------------------------------
PRINT '=== 3. ReportName GL Summary (1155) ===';
IF OBJECT_ID(N'dbo.ReportName', N'U') IS NOT NULL
BEGIN
    SELECT
        CASE WHEN EXISTS (
            SELECT 1 FROM dbo.ReportName
            WHERE ID = 1155
               OR Name LIKE N'%General Ledger Summary%'
               OR Name LIKE N'%GeneralLedgerSummary%'
        ) THEN N'OK' ELSE N'MISSING — Report_GeneralLedgerSummary.sql' END AS Status;

    SELECT TOP 5 ID, Name
    FROM dbo.ReportName
    WHERE ID = 1155
       OR Name LIKE N'%Ledger Summary%'
       OR Name LIKE N'%GeneralLedgerSummary%'
    ORDER BY ID;
END
ELSE
    SELECT N'ReportName table missing' AS Status;

------------------------------------------------------------------------------
-- 4) Summary
------------------------------------------------------------------------------
PRINT '=== 4. Summary ===';
SELECT
    SUM(CASE WHEN Status = N'MISSING' THEN 1 ELSE 0 END) AS ColumnsMissing
FROM (
    SELECT CASE WHEN COL_LENGTH(N'dbo.' + t, c) IS NULL THEN N'MISSING' ELSE N'OK' END AS Status
    FROM (VALUES
        (N'SaleHead', N'IsBankCharges'),
        (N'SaleHead', N'AddAmount'),
        (N'Customer', N'TransportCharges'),
        (N'AccountName', N'AccountCode'),
        (N'AcctGroup', N'GroupCode'),
        (N'AcctSubGroup', N'SubGroupCode'),
        (N'IncomeExpenseHead', N'PrintCheque')
    ) v(t, c)
) x;

SELECT
    SUM(CASE WHEN s = N'MISSING' THEN 1 ELSE 0 END) AS RoutinesMissing,
    SUM(CASE WHEN s = N'OLDER'   THEN 1 ELSE 0 END) AS RoutinesOlder,
    SUM(CASE WHEN s = N'OK'      THEN 1 ELSE 0 END) AS RoutinesOk
FROM (
    SELECT
        CASE
            WHEN OBJECT_ID(N'dbo.' + n) IS NULL THEN N'MISSING'
            WHEN CAST(o.modify_date AS date) < CONVERT(date, d) THEN N'OLDER'
            ELSE N'OK'
        END AS s
    FROM (VALUES
        (N'fn_AccountInFilter', '2026-09-10'),
        (N'GeneralLedgerSummary', '2026-09-10'),
        (N'GeneralLedgerDetailReport', '2026-09-10'),
        (N'GeneralLedgerDetailReport_ND', '2026-09-10'),
        (N'CustomerBalanceDetail', '2026-09-10'),
        (N'SaleHistory', '2026-09-01'),
        (N'CashbookHistory', '2026-08-04'),
        (N'TitanBalanceDetail', '2026-08-08'),
        (N'SaleAdvBalanceCheck', '2026-08-01'),
        (N'CustSupHistory', '2026-08-01'),
        (N'GetNumToMyan1', '2026-08-04'),
        (N'GetNumToMyan2', '2026-08-04')
    ) v(n, d)
    LEFT JOIN sys.objects o ON o.object_id = OBJECT_ID(N'dbo.' + v.n)
) y;

PRINT 'MISSING/OLDER = docs/sql ထဲက DeployScript ကို Cloud မှာ run။';
PRINT 'Checklist: docs/Cloud_SchemaParity_AfterRestore.md';
GO
