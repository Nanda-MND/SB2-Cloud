-- Diagnose k6bsr (CodeID 1933) why CostAmount was 0.
-- Run after deploying SaleProfitFIFO.sql if still zero.

DECLARE @CodeID INT = 1933;
DECLARE @FDate DATETIME = '2026-06-01';
DECLARE @TDate DATETIME = '2026-06-30';
DECLARE @MaxOpnDate DATETIME;

SELECT @MaxOpnDate = MAX(Date)
FROM StockOpeningHead
WHERE ISNULL(Deleted, 0) <> 1 AND Date <= @FDate;

SELECT MaxOpnDate = @MaxOpnDate;

-- Opening lots
SELECT 'Opening' Src, H.Date, H.LocationID, D.CodeID, BrandID = ISNULL(D.BrandID,-1),
       Price = D.Price, Qty = D.Qty, UnitID = D.UnitID
FROM StockOpeningHead H
JOIN StockOpeningDetail D ON H.ID = D.RefID
WHERE ISNULL(H.Deleted,0)<>1 AND H.Date = @MaxOpnDate AND D.CodeID = @CodeID;

-- Purchases
SELECT 'Purchase' Src, H.Date, H.LocationID, D.CodeID, BrandID = ISNULL(D.BrandID,-1),
       Price = D.Price, Qty = D.Qty, CurrencyID = H.CurrencyID
FROM PurchaseHead H
JOIN PurchaseDetail D ON H.ID = D.RefID
WHERE ISNULL(H.Deleted,0)<>1 AND H.Date BETWEEN @MaxOpnDate AND @TDate AND D.CodeID = @CodeID;

-- Shipments (NetPrice)
SELECT 'Shipment' Src, H.Date, H.LocationID, D.CodeID, BrandID = ISNULL(D.BrandID,-1),
       NetPrice = D.NetPrice, Price = D.Price, CostCon = D.CostCon, CostTran = D.CostTran, Qty = D.Qty
FROM StockReceiveHead H
JOIN StockReceiveDetail D ON H.ID = D.RefID
WHERE ISNULL(H.Deleted,0)<>1 AND H.Date BETWEEN @MaxOpnDate AND @TDate AND D.CodeID = @CodeID;

-- Sales in period
SELECT 'Sale' Src, H.Date, LocID = D.LocID, HeadLoc = H.LocationID, D.CodeID,
       BrandID = ISNULL(D.BrandID,-1), Qty = D.Qty, Price = D.Price, Amount = D.Amount
FROM SaleHead H
JOIN SaleDetail D ON H.ID = D.RefID
WHERE ISNULL(H.Deleted,0)<>1 AND dbo.CastDate(H.Date) BETWEEN @FDate AND @TDate AND D.CodeID = @CodeID;

-- StockDetail fallback price
SELECT StockID, UnitID, PurPrice FROM StockDetail WHERE StockID = @CodeID;
