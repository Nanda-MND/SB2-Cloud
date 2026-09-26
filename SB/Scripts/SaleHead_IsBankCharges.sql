/*======================================================================
  SaleHead.IsBankCharges — Bank Charges checkbox persist
  Idempotent. Run on SB2 ERP database.
======================================================================*/
SET NOCOUNT ON;

IF COL_LENGTH(N'dbo.SaleHead', N'IsBankCharges') IS NULL
BEGIN
    ALTER TABLE dbo.SaleHead ADD IsBankCharges bit NOT NULL
        CONSTRAINT DF_SaleHead_IsBankCharges DEFAULT (0);
    PRINT '[OK] Added SaleHead.IsBankCharges';
END
ELSE
    PRINT '[SKIP] SaleHead.IsBankCharges already exists';
GO

-- Separate batch so newly added column is visible to the compiler
SET NOCOUNT ON;

-- Backfill: vouchers that already stored a fee
UPDATE dbo.SaleHead
SET IsBankCharges = 1
WHERE ISNULL(IsBankCharges, 0) = 0
  AND ISNULL(AddAmount, 0) <> 0;

PRINT '[OK] SaleHead_IsBankCharges done';
GO
