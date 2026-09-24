/*
  Local vs Cloud — objects changed since Cloud restore date.

  1) CLOUD: get approximate restore/create date
       SELECT name, create_date FROM sys.databases WHERE name = DB_NAME();
  2) Set @Since below to that date (or slightly before).
  3) Run this script on LOCAL and on CLOUD (same @Since).
  4) Compare result sets (name / modify_date / type_desc).
     Anything on Local newer / missing on Cloud → deploy script.

  Optional: export both result grids and diff in Excel.
*/

SET NOCOUNT ON;

DECLARE @Since datetime2(0) = '2026-06-22';  -- Cloud db_abbe78_warehouse create_date ≈ 2026-06-22 23:23

PRINT '=== DB: ' + DB_NAME() + '  Since: ' + CONVERT(varchar(19), @Since, 120) + ' ===';

PRINT '=== 1. Objects modified since @Since ===';
SELECT
    o.type_desc,
    o.name,
    o.create_date,
    o.modify_date
FROM sys.objects o
WHERE o.schema_id = SCHEMA_ID(N'dbo')
  AND o.type IN ('U', 'P', 'FN', 'IF', 'TF', 'V')
  AND o.is_ms_shipped = 0
  AND o.modify_date >= @Since
ORDER BY o.modify_date DESC, o.type_desc, o.name;

PRINT '=== 2. Key columns (parity check) ===';
SELECT
    OBJECT_NAME(c.object_id) AS TableName,
    c.name AS ColumnName,
    ty.name AS TypeName,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id IN (
    OBJECT_ID(N'dbo.SaleHead'),
    OBJECT_ID(N'dbo.AccountName'),
    OBJECT_ID(N'dbo.AcctGroup'),
    OBJECT_ID(N'dbo.AcctSubGroup'),
    OBJECT_ID(N'dbo.AcctMainGroup')
)
ORDER BY TableName, c.column_id;

PRINT '=== 3. Key routines exist? ===';
SELECT v.name AS ObjectName,
       CASE WHEN OBJECT_ID(N'dbo.' + v.name) IS NULL THEN N'MISSING' ELSE N'EXISTS' END AS Status,
       o.type_desc,
       o.modify_date
FROM (VALUES
    (N'fn_AccountInFilter'),
    (N'GeneralLedgerSummary'),
    (N'GeneralLedgerDetailReport'),
    (N'GeneralLedgerDetailReport_ND'),
    (N'CustomerBalanceDetail'),
    (N'SaleHistory'),
    (N'CashbookHistory'),
    (N'TitanBalanceDetail'),
    (N'SaleAdvBalanceCheck'),
    (N'GetNumToMyan'),
    (N'GetNumToMyan1'),
    (N'GetNumToMyan2')
) v(name)
LEFT JOIN sys.objects o ON o.object_id = OBJECT_ID(N'dbo.' + v.name)
ORDER BY v.name;

PRINT 'Done. Deploy missing/outdated objects using docs/Cloud_SchemaParity_AfterRestore.md';
GO
