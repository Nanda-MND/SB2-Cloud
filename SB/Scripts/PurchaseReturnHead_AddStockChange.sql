-- Required for Purchase Return: adds StockChange flag to PurchaseReturnHead.
-- Run this once on the ERP database, then restart the application.

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.PurchaseReturnHead')
      AND name = 'StockChange'
)
BEGIN
    ALTER TABLE dbo.PurchaseReturnHead
        ADD StockChange BIT NOT NULL
            CONSTRAINT DF_PurchaseReturnHead_StockChange DEFAULT (1);
END
GO

-- Ensure existing rows default to stock-out on return.
UPDATE dbo.PurchaseReturnHead
SET StockChange = 1
WHERE StockChange IS NULL OR StockChange = 0;
GO
