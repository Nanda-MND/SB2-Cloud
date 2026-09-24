-- SaleHead.IsBankCharges for Sales Entry Bank Charges checkbox
IF COL_LENGTH('dbo.SaleHead', 'IsBankCharges') IS NULL
BEGIN
    ALTER TABLE dbo.SaleHead ADD IsBankCharges bit NOT NULL
        CONSTRAINT DF_SaleHead_IsBankCharges DEFAULT (0);
END
GO
