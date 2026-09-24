/*
  Sales list: narrow Car + Discount so Charges/Amount/checkboxes fit on screen.
  App also forces these widths in frm_Main (ApplySalesHistoryColumnWidths).

  Run on: SB1
*/

USE [SB1];
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
