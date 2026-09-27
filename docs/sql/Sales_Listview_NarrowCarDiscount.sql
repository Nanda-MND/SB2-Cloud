/*
  Sales list: narrow Car + Discount so Charges/Amount/checkboxes fit on screen.
  App also forces these widths in frm_Main (ApplySalesHistoryColumnWidths).

  Run on Dev Local SB2, and on Test Cloud after restore.
  Refuses SB1 and the production cloud host.
*/

SET NOCOUNT ON;

IF DB_NAME() IN (N'SB1', N'SB', N'db_abbe78_warehouse', N'db_abe8c0_erp', N'db_abe8c0_luckyone')
   OR DB_NAME() LIKE N'%abbe78%'
   OR CONVERT(nvarchar(256), @@SERVERNAME) LIKE N'%SQL1002%'
   OR CONVERT(nvarchar(256), @@SERVERNAME) LIKE N'%sql8020%'
   OR CONVERT(nvarchar(256), @@SERVERNAME) LIKE N'%sql8010%'
BEGIN
    RAISERROR(N'STOP: refusing SB1, SQL1002, or another account database. Run on local\SB2 or sql8006 / db_abe8c0_sb2.', 16, 1);
    RETURN;
END
GO

IF OBJECT_ID(N'dbo.ListviewItem', N'U') IS NOT NULL
BEGIN
    UPDATE dbo.ListviewItem
    SET ColumnWidth = 55
    WHERE MenuName = N'Sales' AND ColumnName = N'Car';

    UPDATE dbo.ListviewItem
    SET ColumnWidth = 70
    WHERE MenuName = N'Sales' AND ColumnName = N'Discount';

    UPDATE dbo.ListviewItem
    SET ColumnWidth = 70
    WHERE MenuName = N'Sales' AND ColumnName = N'Charges';

    UPDATE dbo.ListviewItem
    SET ColumnWidth = 70
    WHERE MenuName = N'Sales' AND ColumnName IN (N'PaidAmount', N'Paid');

    UPDATE dbo.ListviewItem
    SET ColumnWidth = 40
    WHERE MenuName = N'Sales' AND ColumnName = N'PK';
END
GO

PRINT 'Sales ListviewItem: Car/Discount/Charges widths tightened.';
GO
