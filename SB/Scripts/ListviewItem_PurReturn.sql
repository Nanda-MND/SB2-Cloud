-- Run once on the ERP database after deploying Purchase Return list config fix.
-- Creates ListviewItem rows for MenuName = 'PurReturn' if they do not already exist.
-- Column layout matches frm_Main PurchaseReturn dcol:
-- Date, AutoID, DocumentID, Location, Supplier, Payment, Remark, FAmount, Amount
-- Note: client ListviewItem has no Sr column.

IF NOT EXISTS (SELECT 1 FROM ListviewItem WHERE MenuName = 'PurReturn')
BEGIN
    INSERT INTO ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    SELECT
        'PurReturn',
        CASE ColumnName WHEN 'Customer' THEN 'Supplier' ELSE ColumnName END,
        ColumnWidth,
        CASE ColumnHeader WHEN 'Customer' THEN 'Supplier' ELSE ColumnHeader END
    FROM ListviewItem
    WHERE MenuName = 'SaleReturn';
END

IF NOT EXISTS (SELECT 1 FROM ListviewItem WHERE MenuName = 'PurReturn' AND ColumnName = 'Payment')
BEGIN
    INSERT INTO ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    VALUES ('PurReturn', 'Payment', 100, 'Payment');
END
