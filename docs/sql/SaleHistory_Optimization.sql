/*
  SaleHistory performance optimization for SB ERP
  Run against database: SB1

  Schema notes (from WinForms app + GetSalePK):
  - PK = SUM(SaleDetail.Qty) WHERE CodeID = 1038 only (special charge line)
  - Stock/code filter uses SaleDetail rows WHERE CodeID <> 1038
  - DivID is on Customer; @CarID param = Gate/Division filter from WinForms

  BEFORE RUNNING:
  - Backup the database
  - Compare results with old function after deploy
*/

USE [SB1];
GO

/* ============================================================
   STEP 1 — Indexes
   ============================================================ */

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_SaleHead_Date_Deleted'
      AND object_id = OBJECT_ID(N'dbo.SaleHead')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_SaleHead_Date_Deleted
    ON dbo.SaleHead ([Date], Deleted)
    INCLUDE (
        UserID, LocationID, CustomerID, PaymentID, TransportID, CarID, GateID,
        AccountID, AutoID, DocumentID, SaleID, Remark,
        PaidAmount, Discount, AddAmount, TotalAmount, Printed, Pansar, Issue
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_SaleDetail_RefID_CodeID_LocID'
      AND object_id = OBJECT_ID(N'dbo.SaleDetail')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_SaleDetail_RefID_CodeID_LocID
    ON dbo.SaleDetail (RefID, CodeID, LocID)
    INCLUDE (Qty, Qty1);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Stock_Short'
      AND object_id = OBJECT_ID(N'dbo.Stock')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Stock_Short
    ON dbo.Stock (Short)
    INCLUDE (ID);
END
GO

/* ============================================================
   STEP 2 — Optimized SaleHistory
   ============================================================ */

ALTER FUNCTION [dbo].[SaleHistory] (
    @UserID         INT,
    @FDate          DATETIME,
    @TDate          DATETIME,
    @LocationID     INT,
    @TownshipID     INT,
    @CustomerID     INT,
    @PaymentTypeID  INT,
    @Code           NVARCHAR(20),
    @BrandID        INT,
    @TransportID    INT,
    @CarID          INT
)
RETURNS TABLE
AS
RETURN
(
    WITH DetailFilter AS (
        /*
          Stock/code filter on CodeID <> 1038 only (matches original IN subquery).
          When @Code = '%%' and no Loc filter, skip Stock join.
        */
        SELECT SD.RefID
        FROM dbo.SaleDetail SD
        WHERE SD.CodeID <> 1038
          AND (
                ( @Code IN (N'%', N'%%') AND ISNULL(@BrandID, 0) = 0 )
                OR ( @Code IN (N'%', N'%%') AND ISNULL(SD.LocID, -1) = @BrandID )
                OR EXISTS (
                    SELECT 1
                    FROM dbo.Stock S
                    WHERE S.ID = SD.CodeID
                      AND ISNULL(S.Deleted, 0) <> 1
                      AND S.Short LIKE @Code
                      AND ( ISNULL(@BrandID, 0) = 0 OR ISNULL(SD.LocID, -1) = @BrandID )
                )
              )
        GROUP BY SD.RefID
    ),
    PKAgg AS (
        /* dbo.GetSalePK: SUM(Qty) for CodeID = 1038 only */
        SELECT
            RefID,
            PKTotal = SUM(ISNULL(Qty, 0))
        FROM dbo.SaleDetail
        WHERE CodeID = 1038
        GROUP BY RefID
    )
    SELECT
        H.ID,
        H.[Date],
        H.AutoID,
        Township     = Tsp.Name,
        DocumentID   = ISNULL(CAST(H.DocumentID AS NVARCHAR(10)), H.SaleID),
        Location     = L.Name,
        Customer     = C.Name,
        PK           = ISNULL(PK.PKTotal, 0),
        Payment      = P.Name,
        Transport    = T.Name,
        Car          = CR.Name,
        H.Remark,
        Paid         = SUM(ISNULL(H.PaidAmount, 0)),
        Discount     = SUM(H.Discount),
        /* Bank transfer fee; Amount is always goods+tax-discount (excludes AddAmount) */
        Charges      = SUM(ISNULL(H.AddAmount, 0)),
        Amount       = SUM(ISNULL(H.Amount, 0) - ISNULL(H.Discount, 0) + ISNULL(H.TaxAmount, 0)),
        Printed      = ISNULL(H.Printed, 0),
        Pansar       = ISNULL(H.Pansar, 0),
        Issue        = ISNULL(H.Issue, 0)
    FROM dbo.SaleHead H
    INNER JOIN DetailFilter DF ON DF.RefID = H.ID
    LEFT  JOIN PKAgg PK ON PK.RefID = H.ID
    LEFT  JOIN dbo.Location L ON H.LocationID = L.ID
    INNER JOIN dbo.Customer C ON H.CustomerID = C.ID
    INNER JOIN dbo.Township Tsp ON C.TownshipID = Tsp.ID
    INNER JOIN dbo.PaymentType P ON P.ID = H.PaymentID
    LEFT  JOIN dbo.Transport T ON H.TransportID = T.ID
    LEFT  JOIN dbo.Cars CR ON H.CarID = CR.ID
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND H.[Date] >= CAST(@FDate AS DATE)
      AND H.[Date] <  DATEADD(DAY, 1, CAST(@TDate AS DATE))
      AND H.UserID = CASE WHEN ISNULL(@UserID, 0) = 0 THEN H.UserID ELSE @UserID END
      AND H.LocationID = CASE WHEN @LocationID = -1 THEN H.LocationID ELSE @LocationID END
      /* Original unqualified DivID = Customer.DivID; @CarID is Gate filter from WinForms */
      AND ISNULL(C.DivID, -1) = CASE WHEN @CarID = -1 THEN ISNULL(C.DivID, -1) ELSE @CarID END
      AND C.TownshipID = CASE WHEN @TownshipID = -1 THEN C.TownshipID ELSE @TownshipID END
      AND H.CustomerID = CASE WHEN @CustomerID = -1 THEN H.CustomerID ELSE @CustomerID END
      /* PaymentType (1..5) OR AccountName ID (>5). Account filter ignores PaymentID. */
      AND (
            @PaymentTypeID = -1
            OR (
                @PaymentTypeID < 6
                AND H.PaymentID = @PaymentTypeID
              )
            OR (
                @PaymentTypeID > 5
                AND ISNULL(H.AccountID, 0) = @PaymentTypeID
              )
          )
      AND ISNULL(H.TransportID, -1) = CASE
            WHEN ISNULL(@TransportID, 0) = 0 THEN ISNULL(H.TransportID, -1)
            ELSE @TransportID
          END
    GROUP BY
        H.ID, H.[Date], H.AutoID, Tsp.Name, H.DocumentID, H.SaleID,
        L.Name, C.Name, PK.PKTotal, P.Name, T.Name, CR.Name,
        H.Remark, H.UserID, H.Printed, H.Pansar, H.Issue
);
GO

/* ============================================================
   STEP 3 — Verify (run manually)
   ============================================================
SELECT TOP 20 *
FROM dbo.SaleHistory(
    0, '2026-02-26', '2026-02-26',
    -1, -1, -1, -1, N'%%', 0, 0, 0
);

-- PK check vs GetSalePK:
-- SELECT TOP 10 H.ID, dbo.GetSalePK(H.ID) AS OldPK, PKAgg.PKTotal AS NewPK
-- FROM SaleHead H
-- LEFT JOIN (SELECT RefID, PKTotal = SUM(ISNULL(Qty,0)) FROM SaleDetail WHERE CodeID = 1038 GROUP BY RefID) PKAgg ON PKAgg.RefID = H.ID
-- WHERE ISNULL(H.Deleted,0) <> 1;
*/
