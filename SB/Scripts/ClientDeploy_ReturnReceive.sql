/*======================================================================
  SB2 -- Return/Receive tables, TVFs, menu reports (idempotent)
  Source: SB1 schema + SB project
  Run on client live ERP database (same as ClientDeploy_OneClick.sql)

  Report IDs (SB2 1142-1145 already used):
    1150 parent Purchase Return Reports
    1151-1153 Purchase Return By Invoice / Item Summary / Item Detail
    1154-1156 Return Receive By Invoice / Item Summary / Item Detail
    1157 Purchase Return Balance
  Manufacture Return/Get Stock reports 1135-1141 already exist in ReportName.
======================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
BEGIN
    RAISERROR(N'Select the client ERP database first.', 16, 1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID(N'dbo.ReturnReceiveHead', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReturnReceiveHead
    (
        ID           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Date]       DATETIME      NULL,
        AutoID       NVARCHAR(20)  NULL,
        DocumentID   NVARCHAR(50)  NULL,
        LocationID   INT           NULL,
        SupplierID   INT           NULL,
        Remark       NVARCHAR(200) NULL,
        Amount       MONEY         NULL,
        Deleted      BIT           NULL,
        UserID       INT           NULL,
        EditUserID   INT           NULL,
        EditDate     DATETIME      NULL
    );
    PRINT 'OK: Created ReturnReceiveHead';
END
ELSE PRINT 'SKIP: ReturnReceiveHead';
GO

IF OBJECT_ID(N'dbo.ReturnReceiveDetail', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReturnReceiveDetail
    (
        ID           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RefID        INT           NULL,
        Sr           INT           NULL,
        CodeID       INT           NULL,
        BrandID      INT           NULL,
        ReturnID     INT           NULL,
        Qty          FLOAT         NULL,
        UnitID       INT           NULL,
        Price        MONEY         NULL,
        Weight       FLOAT         NULL,
        Amount       MONEY         NULL,
        TotalWeight  MONEY         NULL,
        Remark       NVARCHAR(50)  NULL,
        Qty1         INT           NULL,
        Qty2         INT           NULL
    );
    CREATE INDEX IX_ReturnReceiveDetail_RefID ON dbo.ReturnReceiveDetail (RefID);
    PRINT 'OK: Created ReturnReceiveDetail';
END
ELSE PRINT 'SKIP: ReturnReceiveDetail';
GO

IF OBJECT_ID(N'dbo.ReturnStockHead', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReturnStockHead
    (
        ID                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Date]                DATETIME      NULL,
        AutoID                NVARCHAR(20)  NULL,
        DocumentID            NVARCHAR(50)  NULL,
        LocationID            INT           NULL,
        ManufacturerID        INT           NULL,
        PaymentID             INT           NULL,
        AccountID             INT           NULL,
        Remark                NVARCHAR(200) NULL,
        Balance               MONEY         NULL,
        Amount                MONEY         NULL,
        Discount              MONEY         NULL,
        NetAmount             MONEY         NULL,
        TaxAmount             MONEY         NULL,
        TotalAmount           MONEY         NULL,
        PaidAmount            MONEY         NULL,
        TotalBalance          MONEY         NULL,
        WeightBalance         FLOAT         NULL,
        TotalWeight           FLOAT         NULL,
        CurrentWeightBalance  FLOAT         NULL,
        Deleted               BIT           NULL,
        UserID                INT           NULL,
        EditUserID            INT           NULL,
        EditDate              DATETIME      NULL,
        Printed               BIT           NULL
    );
    PRINT 'OK: Created ReturnStockHead';
END
ELSE PRINT 'SKIP: ReturnStockHead';
GO

IF OBJECT_ID(N'dbo.ReturnStockDetail', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReturnStockDetail
    (
        ID           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RefID        INT           NULL,
        Sr           INT           NULL,
        CodeID       INT           NULL,
        BrandID      INT           NULL,
        Qty          FLOAT         NULL,
        UnitID       INT           NULL,
        Weight       FLOAT         NULL,
        Price        MONEY         NULL,
        TotalWeight  FLOAT         NULL,
        Amount       MONEY         NULL,
        Remark       NVARCHAR(50)  NULL,
        Qty1         INT           NULL,
        Qty2         FLOAT         NULL
    );
    CREATE INDEX IX_ReturnStockDetail_RefID ON dbo.ReturnStockDetail (RefID);
    PRINT 'OK: Created ReturnStockDetail';
END
ELSE PRINT 'SKIP: ReturnStockDetail';
GO

IF OBJECT_ID(N'dbo.GetStockHead', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GetStockHead
    (
        ID                    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Date]                DATETIME      NULL,
        AutoID                NVARCHAR(20)  NULL,
        DocumentID            NVARCHAR(50)  NULL,
        LocationID            INT           NULL,
        ManufacturerID        INT           NULL,
        PaymentID             INT           NULL,
        AccountID             INT           NULL,
        Remark                NVARCHAR(200) NULL,
        Balance               MONEY         NULL,
        Amount                MONEY         NULL,
        Discount              MONEY         NULL,
        NetAmount             MONEY         NULL,
        TaxAmount             MONEY         NULL,
        TotalAmount           MONEY         NULL,
        PaidAmount            MONEY         NULL,
        TotalBalance          MONEY         NULL,
        WeightBalance         FLOAT         NULL,
        TotalWeight           FLOAT         NULL,
        CurrentWeightBalance  FLOAT         NULL,
        Deleted               BIT           NULL,
        UserID                INT           NULL,
        EditUserID            INT           NULL,
        EditDate              DATETIME      NULL,
        Printed               BIT           NULL
    );
    PRINT 'OK: Created GetStockHead';
END
ELSE PRINT 'SKIP: GetStockHead';
GO

IF OBJECT_ID(N'dbo.GetStockDetail', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GetStockDetail
    (
        ID           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RefID        INT           NULL,
        Sr           INT           NULL,
        CodeID       INT           NULL,
        BrandID      INT           NULL,
        Qty          FLOAT         NULL,
        UnitID       INT           NULL,
        Weight       FLOAT         NULL,
        Price        MONEY         NULL,
        TotalWeight  FLOAT         NULL,
        Amount       MONEY         NULL,
        Remark       NVARCHAR(50)  NULL,
        Qty1         INT           NULL,
        Qty2         FLOAT         NULL,
        OrderRefID   INT           NULL
    );
    CREATE INDEX IX_GetStockDetail_RefID ON dbo.GetStockDetail (RefID);
    PRINT 'OK: Created GetStockDetail';
END
ELSE PRINT 'SKIP: GetStockDetail';
GO

CREATE OR ALTER FUNCTION [dbo].[ReturnReceiveHistory]
(
    @UserID INT, @FDate DATETIME, @TDate DATETIME, @LocationID INT,
    @TownshipID INT, @SupplierID INT, @Code NVARCHAR(20), @BrandID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT H.ID, Date, AutoID, DocumentID, Location = L.Name, Supplier = C.Name,
           Payment = '', H.Remark, Amount = SUM(D.Amount)
    FROM ReturnReceiveHead H
    JOIN ReturnReceiveDetail D ON H.ID = D.RefID
    JOIN Location L ON H.LocationID = L.ID
    JOIN Supplier C ON H.SupplierID = C.ID
    JOIN Stock S ON D.CodeID = S.ID
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND Date BETWEEN @FDate AND @TDate
      AND UserID = (CASE WHEN ISNULL(@UserID, 0) = 0 THEN UserID ELSE @UserID END)
      AND LocationID = (CASE WHEN @LocationID = -1 THEN LocationID ELSE @LocationID END)
      AND TownshipID = (CASE WHEN @TownshipID = -1 THEN TownshipID ELSE @TownshipID END)
      AND SupplierID = (CASE WHEN @SupplierID = -1 THEN SupplierID ELSE @SupplierID END)
      AND H.ID IN
      (
          SELECT RefID FROM ReturnReceiveDetail
          WHERE S.Short LIKE @Code
            AND ISNULL(BrandID, -1) = (CASE WHEN ISNULL(@BrandID, 0) = 0 THEN ISNULL(BrandID, -1) ELSE @BrandID END)
      )
    GROUP BY H.ID, Date, AutoID, DocumentID, L.Name, C.Name, H.Remark, UserID
);
GO
PRINT 'OK: ReturnReceiveHistory';
GO

CREATE OR ALTER FUNCTION [dbo].[ReturnStockHistory]
(
    @UserID INT, @FDate DATETIME, @TDate DATETIME, @LocationID INT,
    @TownshipID INT, @ManufacturerID INT, @PaymentTypeID INT, @Code NVARCHAR(20), @BrandID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT H.ID, Date, AutoID, DocumentID, Location = L.Name, Manufacturer = C.Name,
           Printed = ISNULL(Printed, 0), H.Remark, Amount = SUM(D.Amount)
    FROM ReturnStockHead H
    JOIN ReturnStockDetail D ON H.ID = D.RefID
    JOIN Location L ON H.LocationID = L.ID
    JOIN Manufacturer C ON H.ManufacturerID = C.ID
    JOIN Stock S ON D.CodeID = S.ID
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND Date BETWEEN @FDate AND @TDate
      AND UserID = (CASE WHEN ISNULL(@UserID, 0) = 0 THEN UserID ELSE @UserID END)
      AND LocationID = (CASE WHEN @LocationID = -1 THEN LocationID ELSE @LocationID END)
      AND TownshipID = (CASE WHEN @TownshipID = -1 THEN TownshipID ELSE @TownshipID END)
      AND ManufacturerID = (CASE WHEN @ManufacturerID = -1 THEN ManufacturerID ELSE @ManufacturerID END)
      AND H.ID IN
      (
          SELECT RefID FROM ReturnStockDetail
          WHERE S.Short LIKE @Code
            AND ISNULL(BrandID, -1) = (CASE WHEN ISNULL(@BrandID, 0) = 0 THEN ISNULL(BrandID, -1) ELSE @BrandID END)
      )
    GROUP BY H.ID, Date, AutoID, H.NetAmount, H.Amount, DocumentID, L.Name, C.Name, Printed, H.Remark, UserID
);
GO
PRINT 'OK: ReturnStockHistory';
GO

CREATE OR ALTER FUNCTION [dbo].[GetStockHistory]
(
    @UserID INT, @FDate DATETIME, @TDate DATETIME, @LocationID INT,
    @TownshipID INT, @ManufacturerID INT, @PaymentTypeID INT, @Code NVARCHAR(20), @BrandID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT H.ID, Date, AutoID, DocumentID, Location = L.Name, Manufacturer = C.Name,
           Printed = ISNULL(Printed, 0), H.Remark, Amount = SUM(D.Amount)
    FROM GetStockHead H
    JOIN GetStockDetail D ON H.ID = D.RefID
    JOIN Location L ON H.LocationID = L.ID
    JOIN Manufacturer C ON H.ManufacturerID = C.ID
    JOIN Stock S ON D.CodeID = S.ID
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND Date BETWEEN @FDate AND @TDate
      AND UserID = (CASE WHEN ISNULL(@UserID, 0) = 0 THEN UserID ELSE @UserID END)
      AND LocationID = (CASE WHEN @LocationID = -1 THEN LocationID ELSE @LocationID END)
      AND TownshipID = (CASE WHEN @TownshipID = -1 THEN TownshipID ELSE @TownshipID END)
      AND ManufacturerID = (CASE WHEN @ManufacturerID = -1 THEN ManufacturerID ELSE @ManufacturerID END)
      AND H.ID IN
      (
          SELECT RefID FROM GetStockDetail
          WHERE S.Short LIKE @Code
            AND ISNULL(BrandID, -1) = (CASE WHEN ISNULL(@BrandID, 0) = 0 THEN ISNULL(BrandID, -1) ELSE @BrandID END)
      )
    GROUP BY H.ID, Date, AutoID, H.NetAmount, H.Amount, DocumentID, L.Name, C.Name, Printed, H.Remark, UserID
);
GO
PRINT 'OK: GetStockHistory';
GO

CREATE OR ALTER FUNCTION [dbo].[GetReturnStockByGetStock] (@ManufacturerID INT)
RETURNS @Balance TABLE
(
    Date DATETIME, AutoID NVARCHAR(200), ManufacturerID INT, Customer NVARCHAR(200),
    Short NVARCHAR(20), RefID INT, CodeID INT, BrandID INT, UnitID INT, Qty FLOAT
)
AS
BEGIN
    INSERT INTO @Balance (Date, AutoID, ManufacturerID, Customer, Short, RefID, CodeID, BrandID, UnitID, Qty)
    SELECT Date, AutoID, C.ID, Customer = C.Name, C.Short, RefID, CodeID, BrandID, UnitID, Qty = SUM(Qty)
    FROM
    (
        SELECT RefID, CodeID, BrandID, UnitID, Qty = SUM(Qty)
        FROM ReturnStockDetail D
        JOIN ReturnStockHead H ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ManufacturerID = IIF(@ManufacturerID = 0, ManufacturerID, @ManufacturerID)
        GROUP BY RefID, CodeID, BrandID, UnitID
        UNION ALL
        SELECT OrderRefID, CodeID, BrandID, UnitID, Qty = -SUM(Qty)
        FROM GetStockDetail D
        JOIN GetStockHead H ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ManufacturerID = IIF(@ManufacturerID = 0, ManufacturerID, @ManufacturerID)
        GROUP BY OrderRefID, CodeID, BrandID, UnitID
    ) tmp
    JOIN ReturnStockHead H ON tmp.RefID = H.ID
    JOIN Manufacturer C ON C.ID = H.ManufacturerID
    WHERE ISNULL(H.Deleted, 0) <> 1
    GROUP BY Date, AutoID, C.ID, C.Name, C.Short, RefID, CodeID, BrandID, UnitID
    HAVING SUM(Qty) > 0;
    RETURN;
END
GO
PRINT 'OK: GetReturnStockByGetStock';
GO

CREATE OR ALTER FUNCTION [dbo].[GetReturnBalReceive] (@SupplierID INT)
RETURNS @OrderBalance TABLE
(
    Date DATETIME, AutoID NVARCHAR(200), DocumentID NVARCHAR(200), Customer NVARCHAR(200),
    Short NVARCHAR(20), RefID INT, CodeID INT, BrandID INT, UnitID INT,
    Qty FLOAT, Qty1 INT, Qty2 INT, Price MONEY, Weight FLOAT, Sr INT
)
AS
BEGIN
    INSERT INTO @OrderBalance (Date, AutoID, DocumentID, Customer, Short, RefID, CodeID, BrandID, UnitID, Qty, Qty1, Qty2, Price, Weight, Sr)
    SELECT Date, AutoID, DocumentID, Customer = C.Name, C.Short, tmp.RefID, tmp.CodeID, tmp.BrandID, tmp.UnitID,
           Qty = SUM(tmp.Qty), Qty1 = SUM(tmp.Qty1), MAX(D.Qty2), D.Price, D.Weight, D.Sr
    FROM
    (
        SELECT RefID, CodeID, BrandID, UnitID, Qty = SUM(Qty), Qty1 = SUM(Qty1)
        FROM PurchaseReturnDetail D
        JOIN PurchaseReturnHead H ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND ISNULL(StockChange, 0) = 1
          AND SupplierID = IIF(@SupplierID = 0, SupplierID, @SupplierID)
        GROUP BY RefID, CodeID, BrandID, UnitID
        UNION ALL
        SELECT D.ReturnID, CodeID, BrandID, UnitID, Qty = -SUM(Qty), Qty1 = -SUM(Qty1)
        FROM ReturnReceiveHead H
        JOIN ReturnReceiveDetail D ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND SupplierID = IIF(@SupplierID = 0, SupplierID, @SupplierID)
        GROUP BY D.ReturnID, CodeID, BrandID, UnitID
    ) tmp
    JOIN PurchaseReturnHead H ON tmp.RefID = H.ID
    JOIN PurchaseReturnDetail D ON tmp.RefID = D.RefID AND tmp.CodeID = D.CodeID
    JOIN Supplier C ON C.ID = H.SupplierID
    WHERE ISNULL(H.Deleted, 0) <> 1
    GROUP BY Date, AutoID, DocumentID, C.Name, C.Short, tmp.RefID, tmp.CodeID, tmp.BrandID, tmp.UnitID, Price, Weight, D.Sr
    HAVING SUM(tmp.Qty) <> 0
    ORDER BY D.Sr;
    RETURN;
END
GO
PRINT 'OK: GetReturnBalReceive';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ListviewItem WHERE MenuName = N'ReturnGet')
BEGIN
    INSERT INTO dbo.ListviewItem (MenuName, ColumnName, ColumnWidth, ColumnHeader)
    SELECT N'ReturnGet', ColumnName, ColumnWidth, ColumnHeader
    FROM dbo.ListviewItem
    WHERE MenuName = N'Raw';
    PRINT 'OK: ListviewItem ReturnGet';
END
ELSE PRINT 'SKIP: ListviewItem ReturnGet';
GO

/*======================================================================
  MenuSub rows required by dbo.CheckUserRights:
    Join is UserRights.MenuSubID = MenuSub.MenuID
    and MenuSub.TranID = left-menu group (2=Purchase, 5=Manufacture, 1=Sales)
  Without these rows, new PageMenus stay hidden even if UserRights exist.
======================================================================*/
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 30 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (2, N'Return Stock', 30, 0, 5);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 31 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (2, N'Get Stock', 31, 0, 5);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 32 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (2, N'Return Receive', 32, 0, 2);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 33 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (2, N'Goods Issue', 33, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 34 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (2, N'Goods Receive', 34, 0, 2);
IF NOT EXISTS (SELECT 1 FROM dbo.MenuSub WHERE MenuID = 35 AND TypeID = 2 AND ISNULL(Deleted,0) = 0)
    INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
    VALUES (2, N'Goods Receive (Manu)', 35, 0, 5);
PRINT 'OK: MenuSub transaction menus 30-35';
GO

-- UserRights for transaction menus (UserRights.MenuID is always 2 = Transactions)
INSERT INTO dbo.UserRights (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport, Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT UR.UserID, M.NewSub, 2, UR.AllowTransaction, UR.AllowEdit, UR.AllowDelete, UR.AllowPrint, UR.AllowExport, UR.Reprint, UR.DateChange, UR.AllowExportDOC, UR.AllowExportPDF
FROM dbo.UserRights UR
CROSS JOIN (VALUES
    (32, 7),   -- Return Receive  <- Purchase Return
    (34, 6),   -- Goods Receive   <- Shipments/Receive
    (30, 24),  -- Return Stock    <- Raw Issue
    (31, 24),  -- Get Stock       <- Raw Issue
    (33, 3)    -- Goods Issue     <- Sale Return
    -- (35, 25) Goods Receive Manu — disabled site-wide; see Disable_GoodsReceiveManu_Menu35.sql
) M(NewSub, FromSub)
WHERE UR.MenuSubID = M.FromSub AND UR.MenuID = 2 AND ISNULL(UR.AllowTransaction,0) = 1
  AND NOT EXISTS (
        SELECT 1 FROM dbo.UserRights X
        WHERE X.UserID = UR.UserID AND X.MenuSubID = M.NewSub AND X.MenuID = 2
  );
PRINT 'OK: UserRights menus 30/31/32/33/34/35 insert';
GO

UPDATE T
SET
    AllowTransaction = S.AllowTransaction,
    AllowEdit        = S.AllowEdit,
    AllowDelete      = S.AllowDelete,
    AllowPrint       = S.AllowPrint,
    AllowExport      = S.AllowExport,
    Reprint          = S.Reprint,
    DateChange       = S.DateChange,
    AllowExportDOC   = S.AllowExportDOC,
    AllowExportPDF   = S.AllowExportPDF
FROM dbo.UserRights T
JOIN (VALUES (32, 7), (34, 6), (30, 24), (31, 24), (33, 3)) M(NewSub, FromSub)
  ON T.MenuSubID = M.NewSub AND T.MenuID = 2
JOIN dbo.UserRights S ON S.UserID = T.UserID AND S.MenuSubID = M.FromSub AND S.MenuID = 2
WHERE ISNULL(S.AllowTransaction,0) = 1
  AND ISNULL(T.AllowTransaction,0) = 0;
PRINT 'OK: UserRights menus 30-35 enabled';
GO

DELETE D
FROM dbo.UserRights D
WHERE D.MenuID = 2
  AND D.MenuSubID IN (30,31,32,33,34)
  AND ISNULL(D.AllowTransaction,0) = 0
  AND EXISTS (
        SELECT 1 FROM dbo.UserRights E
        WHERE E.UserID = D.UserID AND E.MenuID = 2 AND E.MenuSubID = D.MenuSubID
          AND ISNULL(E.AllowTransaction,0) = 1
  );
PRINT 'OK: UserRights duplicate disabled rows removed';
GO

-- Reports 1150-1157 (Purchase Return / Return Receive)
IF NOT EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1150)
BEGIN
    BEGIN TRY
        SET IDENTITY_INSERT dbo.ReportName ON;
        INSERT INTO dbo.ReportName (ID, isRoot, RefID, Name, isVisible, SortID)
        VALUES
            (1150, 1, 0,    N'Purchase Return Reports', 1, 30),
            (1151, 0, 1150, N'Purchase Return By Each Invoice', 1, 1),
            (1152, 0, 1150, N'Purchase Return By Item Summary', 1, 2),
            (1153, 0, 1150, N'Purchase Return By Item Detail', 1, 3),
            (1154, 0, 1150, N'Return Receive By Each Invoice', 1, 4),
            (1155, 0, 1150, N'Return Receive By Item Summary', 1, 5),
            (1156, 0, 1150, N'Return Receive By Item Detail', 1, 6),
            (1157, 0, 1150, N'Purchase Return Balance', 1, 7);
        SET IDENTITY_INSERT dbo.ReportName OFF;
        DECLARE @MaxReportID INT = (SELECT MAX(ID) FROM dbo.ReportName);
        DBCC CHECKIDENT (N'dbo.ReportName', RESEED, @MaxReportID);
        PRINT 'OK: ReportName 1150-1157';
    END TRY
    BEGIN CATCH
        SET IDENTITY_INSERT dbo.ReportName OFF;
        THROW;
    END CATCH
END
ELSE PRINT 'SKIP: ReportName 1150-1157';
GO

INSERT INTO dbo.UserRights (UserID, MenuSubID, MenuID, AllowTransaction, AllowEdit, AllowDelete, AllowPrint, AllowExport, Reprint, DateChange, AllowExportDOC, AllowExportPDF)
SELECT UR.UserID, R.ID, 3, UR.AllowTransaction, UR.AllowEdit, UR.AllowDelete, UR.AllowPrint, UR.AllowExport, UR.Reprint, UR.DateChange, UR.AllowExportDOC, UR.AllowExportPDF
FROM dbo.UserRights UR
CROSS JOIN (VALUES (1150),(1151),(1152),(1153),(1154),(1155),(1156),(1157)) R(ID)
WHERE UR.MenuSubID = 1013 AND UR.MenuID = 3
  AND NOT EXISTS (
        SELECT 1 FROM dbo.UserRights X
        WHERE X.UserID = UR.UserID AND X.MenuSubID = R.ID AND X.MenuID = 3
  );
PRINT 'OK: UserRights reports 1150-1157';
GO

-- MenuSub rows for report IDs (required by CheckUserRights + User Setup > Reports)
DECLARE @Rpt TABLE (ReportID INT PRIMARY KEY, ReportName NVARCHAR(200));
INSERT INTO @Rpt VALUES
    (1151, N'Purchase Return By Each Invoice'),
    (1152, N'Purchase Return By Item Summary'),
    (1153, N'Purchase Return By Item Detail'),
    (1154, N'Return Receive By Each Invoice'),
    (1155, N'Return Receive By Item Summary'),
    (1156, N'Return Receive By Item Detail'),
    (1157, N'Purchase Return Balance');

INSERT INTO dbo.MenuSub (TypeID, Name, MenuID, Deleted, TranID)
SELECT 3, R.ReportName, R.ReportID, 0, NULL
FROM @Rpt R
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.MenuSub M
    WHERE M.TypeID = 3 AND M.MenuID = R.ReportID AND ISNULL(M.Deleted,0) = 0
);
PRINT 'OK: MenuSub reports 1151-1157';
GO

UPDATE T SET AllowTransaction = 1
FROM dbo.UserRights T
WHERE T.MenuID = 3 AND T.MenuSubID IN (1151,1152,1153,1154,1155,1156,1157)
  AND ISNULL(T.AllowTransaction,0) = 0
  AND EXISTS (
        SELECT 1 FROM dbo.UserRights S
        WHERE S.UserID = T.UserID AND S.MenuSubID = 1013 AND S.MenuID = 3
          AND ISNULL(S.AllowTransaction,0) = 1
  );
PRINT 'OK: UserRights AllowTransaction enabled for 1151-1157';
GO

-- Site policy: Manufacture > Goods Receive (menu 35) disabled for all users
UPDATE dbo.UserRights
SET AllowTransaction = 0, AllowEdit = 0, AllowDelete = 0, AllowPrint = 0, AllowExport = 0
WHERE MenuID = 2 AND MenuSubID = 35;
PRINT 'OK: Goods Receive (Manu) menu 35 disabled for all users';
GO

PRINT '===== VERIFICATION =====';
SELECT CheckName, Status
FROM
(
    SELECT 1 AS Ord, N'ReturnReceiveHead' AS CheckName, CASE WHEN OBJECT_ID(N'dbo.ReturnReceiveHead', N'U') IS NULL THEN N'MISSING' ELSE N'OK' END AS Status
    UNION ALL SELECT 2, N'ReturnStockHead', CASE WHEN OBJECT_ID(N'dbo.ReturnStockHead', N'U') IS NULL THEN N'MISSING' ELSE N'OK' END
    UNION ALL SELECT 3, N'GetStockHead', CASE WHEN OBJECT_ID(N'dbo.GetStockHead', N'U') IS NULL THEN N'MISSING' ELSE N'OK' END
    UNION ALL SELECT 4, N'ReturnReceiveHistory', CASE WHEN OBJECT_ID(N'dbo.ReturnReceiveHistory') IS NULL THEN N'MISSING' ELSE N'OK' END
    UNION ALL SELECT 5, N'GetReturnBalReceive', CASE WHEN OBJECT_ID(N'dbo.GetReturnBalReceive') IS NULL THEN N'MISSING' ELSE N'OK' END
    UNION ALL SELECT 6, N'GetReturnStockByGetStock', CASE WHEN OBJECT_ID(N'dbo.GetReturnStockByGetStock') IS NULL THEN N'MISSING' ELSE N'OK' END
    UNION ALL SELECT 7, N'ReportName 1150', CASE WHEN EXISTS (SELECT 1 FROM ReportName WHERE ID = 1150) THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 8, N'MenuSub ReturnReceive(32)', CASE WHEN EXISTS (SELECT 1 FROM MenuSub WHERE MenuID=32 AND TypeID=2 AND ISNULL(Deleted,0)=0) THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 9, N'MenuSub ReturnStock(30)', CASE WHEN EXISTS (SELECT 1 FROM MenuSub WHERE MenuID=30 AND TypeID=2 AND ISNULL(Deleted,0)=0) THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 10, N'MenuSub GetStock(31)', CASE WHEN EXISTS (SELECT 1 FROM MenuSub WHERE MenuID=31 AND TypeID=2 AND ISNULL(Deleted,0)=0) THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 11, N'MenuSub GoodsReceive(34)', CASE WHEN EXISTS (SELECT 1 FROM MenuSub WHERE MenuID=34 AND TypeID=2 AND ISNULL(Deleted,0)=0) THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 12, N'GoodsRecvManu disabled', CASE WHEN dbo.CheckUserRights(1,2,35,5)=0 THEN N'OK' ELSE N'FAIL' END
    UNION ALL SELECT 13, N'CheckUserRights RetRecv', CASE WHEN dbo.CheckUserRights(1,2,32,2)=1 THEN N'OK' ELSE N'FAIL' END
    UNION ALL SELECT 14, N'CheckUserRights RetStock', CASE WHEN dbo.CheckUserRights(1,2,30,5)=1 THEN N'OK' ELSE N'FAIL' END
    UNION ALL SELECT 15, N'MenuSub Report 1151', CASE WHEN EXISTS (SELECT 1 FROM MenuSub WHERE TypeID=3 AND MenuID=1151 AND ISNULL(Deleted,0)=0) THEN N'OK' ELSE N'MISSING' END
    UNION ALL SELECT 16, N'CheckUserRights Report 1151', CASE WHEN dbo.CheckUserRights(1,3,1151,0)=1 THEN N'OK' ELSE N'FAIL' END
) v
ORDER BY Ord;
GO
