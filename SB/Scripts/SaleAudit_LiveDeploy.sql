/*
  Live DB — Sale Edit/Delete Audit (no SQLCMD / no :r).
  Run this entire script once on SB2 database in SSMS.
*/
SET NOCOUNT ON;
GO

/* ===== Tables + view ===== */
IF OBJECT_ID(N'dbo.SaleAuditHead', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SaleAuditHead
    (
        ID              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SaleHeadID      INT           NOT NULL,
        Action          CHAR(1)       NOT NULL,
        UserID          INT           NOT NULL,
        ActionDate      DATETIME      NOT NULL CONSTRAINT DF_SaleAuditHead_ActionDate DEFAULT (GETDATE()),
        InvoiceDate     DATETIME      NULL,
        OldDate         DATETIME      NULL,
        NewDate         DATETIME      NULL,
        AutoID          NVARCHAR(50)  NULL,
        DocumentID      NVARCHAR(50)  NULL,
        SaleID          INT           NULL,
        CustomerID      INT           NULL,
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
        LineAction      CHAR(1)       NOT NULL,
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

/* Existing DB: add Old/New date + customer columns */
IF COL_LENGTH(N'dbo.SaleAuditHead', N'OldDate') IS NULL
    ALTER TABLE dbo.SaleAuditHead ADD OldDate DATETIME NULL;
IF COL_LENGTH(N'dbo.SaleAuditHead', N'NewDate') IS NULL
    ALTER TABLE dbo.SaleAuditHead ADD NewDate DATETIME NULL;
IF COL_LENGTH(N'dbo.SaleAuditHead', N'OldCustomerID') IS NULL
    ALTER TABLE dbo.SaleAuditHead ADD OldCustomerID INT NULL;
IF COL_LENGTH(N'dbo.SaleAuditHead', N'NewCustomerID') IS NULL
    ALTER TABLE dbo.SaleAuditHead ADD NewCustomerID INT NULL;
PRINT '[OK] SaleAuditHead Old/New Date+Customer columns';
GO

IF OBJECT_ID(N'dbo.vw_SaleAuditLog', N'V') IS NOT NULL
    DROP VIEW dbo.vw_SaleAuditLog;
GO

CREATE VIEW dbo.vw_SaleAuditLog
AS
SELECT
    H.ID AS AuditID,
    H.ActionDate,
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

/* ===== Report menu ===== */
IF NOT EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1160)
BEGIN
    BEGIN TRY
        SET IDENTITY_INSERT dbo.ReportName ON;
        INSERT INTO dbo.ReportName (ID, isRoot, RefID, Name, isVisible, SortID)
        VALUES
            (1160, 1, 0,    N'Sales Audit Reports', 1, 35),
            (1161, 0, 1160, N'Sale Edit/Delete Log', 1, 1);
        SET IDENTITY_INSERT dbo.ReportName OFF;
        DECLARE @MaxReportID INT = (SELECT MAX(ID) FROM dbo.ReportName);
        DBCC CHECKIDENT (N'dbo.ReportName', RESEED, @MaxReportID);
        PRINT '[OK] ReportName 1160-1161';
    END TRY
    BEGIN CATCH
        SET IDENTITY_INSERT dbo.ReportName OFF;
        THROW;
    END CATCH
END
ELSE
    PRINT '[SKIP] ReportName 1160 already exists';
GO

/* Deduplicate UserRights (duplicate rows → duplicate tree nodes in frm_Reports) */
;WITH d AS (
    SELECT ID,
           rn = ROW_NUMBER() OVER (
               PARTITION BY UserID, MenuSubID, MenuID
               ORDER BY ID
           )
    FROM dbo.UserRights
    WHERE MenuID = 3 AND MenuSubID IN (1160, 1161)
)
DELETE FROM dbo.UserRights
WHERE ID IN (SELECT ID FROM d WHERE rn > 1);
PRINT '[OK] Deduped UserRights 1160/1161';

/* Restrict to UserID 1 and 3 only */
DELETE FROM dbo.UserRights
WHERE MenuID = 3
  AND MenuSubID IN (1160, 1161)
  AND UserID NOT IN (1, 3);
PRINT '[OK] Removed 1160/1161 rights for users other than 1,3';

INSERT INTO dbo.UserRights
    (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport,
     Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT U.UserID, R.ID, 3, 1, 0, 0, 1, 1, 0, 0, 1, 1
FROM (VALUES (1), (3)) U(UserID)
CROSS JOIN (VALUES (1160), (1161)) R(ID)
WHERE NOT EXISTS (
        SELECT 1 FROM dbo.UserRights X
        WHERE X.UserID = U.UserID AND X.MenuSubID = R.ID AND X.MenuID = 3
  );
PRINT '[OK] UserRights 1160-1161 for UserID 1,3 only';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE TypeID = 3 AND MenuID = 1160 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (3, N'Sales Audit Reports', 1160, 0, NULL);

IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE TypeID = 3 AND MenuID = 1161 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (3, N'Sale Edit/Delete Log', 1161, 0, NULL);

/* Soft-delete duplicate MenuSub rows for 1160/1161 */
;WITH m AS (
    SELECT ID,
           rn = ROW_NUMBER() OVER (
               PARTITION BY TypeID, MenuID
               ORDER BY ID
           )
    FROM dbo.MenuSub
    WHERE TypeID = 3 AND MenuID IN (1160, 1161) AND ISNULL(Deleted, 0) = 0
)
UPDATE dbo.MenuSub
SET Deleted = 1
WHERE ID IN (SELECT ID FROM m WHERE rn > 1);

PRINT '[OK] MenuSub 1160-1161';
GO

/* ===== Verify ===== */
SELECT Step = 1, Item = N'SaleAuditHead',
       Status = CASE WHEN OBJECT_ID(N'dbo.SaleAuditHead', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 2, N'SaleAuditDetail',
       CASE WHEN OBJECT_ID(N'dbo.SaleAuditDetail', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 3, N'vw_SaleAuditLog',
       CASE WHEN OBJECT_ID(N'dbo.vw_SaleAuditLog', N'V') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 4, N'ReportName 1160',
       CASE WHEN EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1160) THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 5, N'ReportName 1161',
       CASE WHEN EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1161) THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 6, N'MenuSub 1161',
       CASE WHEN EXISTS (SELECT 1 FROM dbo.MenuSub WHERE TypeID = 3 AND MenuID = 1161 AND ISNULL(Deleted,0) = 0)
            THEN N'OK' ELSE N'MISSING' END
ORDER BY Step;
GO

PRINT '[DONE] SaleAudit_LiveDeploy — rebuild/deploy SB.exe next';
GO
