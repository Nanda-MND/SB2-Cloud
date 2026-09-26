/*
  Live DB alter — add Old/New invoice date + customer to SaleAuditHead.
  Safe to re-run.
*/
SET NOCOUNT ON;
GO

IF COL_LENGTH(N'dbo.SaleAuditHead', N'OldDate') IS NULL
BEGIN
    ALTER TABLE dbo.SaleAuditHead ADD OldDate DATETIME NULL;
    PRINT '[OK] Added SaleAuditHead.OldDate';
END
ELSE PRINT '[SKIP] OldDate';

IF COL_LENGTH(N'dbo.SaleAuditHead', N'NewDate') IS NULL
BEGIN
    ALTER TABLE dbo.SaleAuditHead ADD NewDate DATETIME NULL;
    PRINT '[OK] Added SaleAuditHead.NewDate';
END
ELSE PRINT '[SKIP] NewDate';

IF COL_LENGTH(N'dbo.SaleAuditHead', N'OldCustomerID') IS NULL
BEGIN
    ALTER TABLE dbo.SaleAuditHead ADD OldCustomerID INT NULL;
    PRINT '[OK] Added SaleAuditHead.OldCustomerID';
END
ELSE PRINT '[SKIP] OldCustomerID';

IF COL_LENGTH(N'dbo.SaleAuditHead', N'NewCustomerID') IS NULL
BEGIN
    ALTER TABLE dbo.SaleAuditHead ADD NewCustomerID INT NULL;
    PRINT '[OK] Added SaleAuditHead.NewCustomerID';
END
ELSE PRINT '[SKIP] NewCustomerID';
GO

/* Backfill from legacy InvoiceDate / CustomerID when present */
IF COL_LENGTH(N'dbo.SaleAuditHead', N'InvoiceDate') IS NOT NULL
BEGIN
    UPDATE dbo.SaleAuditHead
    SET OldDate = ISNULL(OldDate, InvoiceDate),
        NewDate = ISNULL(NewDate, InvoiceDate)
    WHERE OldDate IS NULL OR NewDate IS NULL;
END

IF COL_LENGTH(N'dbo.SaleAuditHead', N'CustomerID') IS NOT NULL
BEGIN
    UPDATE dbo.SaleAuditHead
    SET OldCustomerID = ISNULL(OldCustomerID, CustomerID),
        NewCustomerID = ISNULL(NewCustomerID, CustomerID)
    WHERE OldCustomerID IS NULL OR NewCustomerID IS NULL;
END
GO

PRINT '[DONE] SaleAudit_Alter_OldNewDateCustomer';
GO
