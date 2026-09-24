/*
  SaleHistory: Payment filter by bank/wallet AccountID (e.g. apm-AYA PAY Merchant).

  Filter:
  - PaymentType (Cash/Credit/…) → that PaymentID (account ရှိ/မရှိ)
  - Account (apm/…) → AccountID match, any PaymentID (Cash/Credit/Banking)

  Payment COLUMN (list): always PaymentType name only — Cash / Credit / OB …
  (NOT account name like apm-AYA PAY Merchant)

  Re-run this script on SB1 after pull — app rebuild alone will not update dbo.SaleHistory.
*/

USE [SB1];
GO

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
      AND ISNULL(C.DivID, -1) = CASE WHEN @CarID = -1 THEN ISNULL(C.DivID, -1) ELSE @CarID END
      AND C.TownshipID = CASE WHEN @TownshipID = -1 THEN C.TownshipID ELSE @TownshipID END
      AND H.CustomerID = CASE WHEN @CustomerID = -1 THEN H.CustomerID ELSE @CustomerID END
      /* PaymentType ID (1..5) OR AccountName ID (>5). Account filter ignores PaymentID. */
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

PRINT 'SaleHistory: Payment column = Cash/Credit (PaymentType); Account filter matches any PaymentID.';
GO
