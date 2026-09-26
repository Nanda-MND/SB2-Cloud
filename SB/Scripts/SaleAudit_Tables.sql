/*
  Sale Edit/Delete audit tables (Sales only, line-level).
  Safe to re-run on live DB.
*/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.SaleAuditHead', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SaleAuditHead
    (
        ID              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SaleHeadID      INT           NOT NULL,
        Action          CHAR(1)       NOT NULL,  -- E=Edit, D=Delete
        UserID          INT           NOT NULL,
        ActionDate      DATETIME      NOT NULL CONSTRAINT DF_SaleAuditHead_ActionDate DEFAULT (GETDATE()), -- when Edit/Delete was done
        InvoiceDate     DATETIME      NULL,  -- legacy single snapshot (kept for older rows)
        OldDate         DATETIME      NULL,  -- invoice date before change
        NewDate         DATETIME      NULL,  -- invoice date after change
        AutoID          NVARCHAR(50)  NULL,
        DocumentID      NVARCHAR(50)  NULL,
        SaleID          INT           NULL,
        CustomerID      INT           NULL,  -- legacy
        OldCustomerID   INT           NULL,
        NewCustomerID   INT           NULL,
        LocationID      INT           NULL,
        Amount          DECIMAL(18,2) NULL,
        Discount        DECIMAL(18,2) NULL,
        NetAmount       DECIMAL(18,2) NULL,
        TaxAmount       DECIMAL(18,2) NULL,
        AddAmount       DECIMAL(18,2) NULL,
        TotalAmount     DECIMAL(18,2) NULL,
        PaidAmount      DECIMAL(18,2) NULL,
        OldTotalAmount  DECIMAL(18,2) NULL,
        NewTotalAmount  DECIMAL(18,2) NULL
    );
    CREATE INDEX IX_SaleAuditHead_ActionDate ON dbo.SaleAuditHead (ActionDate);
    CREATE INDEX IX_SaleAuditHead_SaleHeadID ON dbo.SaleAuditHead (SaleHeadID);
    PRINT '[OK] Created dbo.SaleAuditHead';
END
ELSE
    PRINT '[SKIP] dbo.SaleAuditHead already exists';
GO

IF OBJECT_ID(N'dbo.SaleAuditDetail', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SaleAuditDetail
    (
        ID              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        AuditID         INT           NOT NULL,
        LineAction      CHAR(1)       NOT NULL,  -- A=Add, U=Update, D=Delete
        SaleDetailID    INT           NULL,
        Sr              INT           NULL,
        CodeID          INT           NULL,
        BrandID         INT           NULL,
        UnitID          INT           NULL,
        OldQty          FLOAT         NULL,
        OldPrice        FLOAT         NULL,
        OldAmount       FLOAT         NULL,
        OldWeight       FLOAT         NULL,
        OldQty1         FLOAT         NULL,
        OldQty2         FLOAT         NULL,
        NewQty          FLOAT         NULL,
        NewPrice        FLOAT         NULL,
        NewAmount       FLOAT         NULL,
        NewWeight       FLOAT         NULL,
        NewQty1         FLOAT         NULL,
        NewQty2         FLOAT         NULL,
        Remark          NVARCHAR(255) NULL,
        CONSTRAINT FK_SaleAuditDetail_Head FOREIGN KEY (AuditID)
            REFERENCES dbo.SaleAuditHead (ID)
    );
    CREATE INDEX IX_SaleAuditDetail_AuditID ON dbo.SaleAuditDetail (AuditID);
    PRINT '[OK] Created dbo.SaleAuditDetail';
END
ELSE
    PRINT '[SKIP] dbo.SaleAuditDetail already exists';
GO

IF OBJECT_ID(N'dbo.vw_SaleAuditLog', N'V') IS NOT NULL
    DROP VIEW dbo.vw_SaleAuditLog;
GO

CREATE VIEW dbo.vw_SaleAuditLog
AS
SELECT
    H.ID AS AuditID,
    H.ActionDate,  -- Edit/Delete performed at
    ActionName = CASE H.Action WHEN 'E' THEN N'Edit' WHEN 'D' THEN N'Delete' ELSE H.Action END,
    H.SaleHeadID,
    H.AutoID,
    H.DocumentID,
    OldDate = ISNULL(H.OldDate, H.InvoiceDate),
    NewDate = ISNULL(H.NewDate, H.InvoiceDate),
    OldCustomer = OC.Name,
    NewCustomer = NC.Name,
    Customer = ISNULL(NC.Name, OC.Name),
    Location = L.Short,
    Users = ISNULL(U.Short, U.Name),
    H.UserID,
    H.OldTotalAmount,
    H.NewTotalAmount,
    H.Amount,
    H.Discount,
    H.NetAmount,
    H.TaxAmount,
    H.AddAmount,
    H.TotalAmount,
    H.PaidAmount,
    D.ID AS AuditDetailID,
    LineActionName = CASE D.LineAction
        WHEN 'A' THEN N'Add'
        WHEN 'U' THEN N'Update'
        WHEN 'D' THEN N'Delete'
        ELSE N'Head'
    END,
    D.LineAction,
    D.SaleDetailID,
    D.Sr,
    Code = S.Short,
    Stock = S.Name,
    Brand = B.Short,
    Unit = UN.Name,
    D.OldQty,
    D.NewQty,
    D.OldPrice,
    D.NewPrice,
    D.OldAmount,
    D.NewAmount,
    D.Remark
FROM dbo.SaleAuditHead H
LEFT JOIN dbo.SaleAuditDetail D ON D.AuditID = H.ID
LEFT JOIN dbo.Customer OC ON OC.ID = ISNULL(H.OldCustomerID, H.CustomerID)
LEFT JOIN dbo.Customer NC ON NC.ID = ISNULL(H.NewCustomerID, H.CustomerID)
LEFT JOIN dbo.Location L ON L.ID = H.LocationID
LEFT JOIN dbo.Users U ON U.ID = H.UserID
LEFT JOIN dbo.Stock S ON S.ID = D.CodeID
LEFT JOIN dbo.Brand B ON B.ID = D.BrandID
LEFT JOIN dbo.Unit UN ON UN.ID = D.UnitID;
GO

PRINT '[OK] SaleAudit_Tables done';
GO
