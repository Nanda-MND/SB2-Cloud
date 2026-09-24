/*
  GetSaleOrderBalSales — fix duplicate (3496) + restore missing rows (2609)

  Deploy on LOCAL, CLOUD, and DEV — TVFs are NOT synced by SyncAgent.

  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -i GetSaleOrderBalSales_Fix.sql
  sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P xxx -C -I -i GetSaleOrderBalSales_Fix.sql

  Root cause (2609 / pplplst rows missing):
    Previous rewrite (Block 2 CROSS APPLY) used:
      AND OD.Qty1 = D.Qty1 AND OD.Qty2 = D.Qty2
    SQL NULL = NULL is UNKNOWN, not TRUE. pplplst order lines (RefID 6481/6517)
    have NULL Qty1/Qty2 → OrdQty = 0, BalQty = 0 → filtered out by Bal.BalQty > 0.

  GetSaleOrderBalSalesList (not in repo) still uses the original tmp-union logic with
  loose RefID+CodeID join, so those rows appear there.

  Fix strategy (aligns with List / original TVF):
    - Restore tmp-union blocks (order qty minus sold qty)
    - Tighten SaleOrderDetail join to stop 3496 duplicates (BrandID + UnitID + Qty1/Qty2)
    - Use ISNULL for Qty1/Qty2 so NULL lines still match
    - Do NOT add tmp.Qty = D.Qty (breaks 3496 sale subtraction)
    - Block 1: D.Qty, isSales <> 1, no HAVING (3496 special-case preserved)
    - Block 2: SUM(tmp.Qty), HAVING > 0, date > 2025-12-19, no isSales filter
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.GetSaleOrderBalSales', N'TF') IS NULL
BEGIN
    RAISERROR(N'GetSaleOrderBalSales does not exist. Paste CREATE FUNCTION from client DB first.', 16, 1);
    RETURN;
END
GO

ALTER FUNCTION [dbo].[GetSaleOrderBalSales] (@CustomerID int)
RETURNS @OrderBalance TABLE (
    Date     Datetime,
    AutoID   nvarchar(200),
    Customer nvarchar(200),
    Short    nvarchar(20),
    RefID    int,
    CodeID   int,
    BrandID  int,
    UnitID   int,
    Qty      float,
    Qty1     float,
    Qty2     float,
    Price    money,
    Weight   float,
    Sr       int,
    Remark   Nvarchar(100)
)
AS
BEGIN
    DECLARE @OpDate Datetime;
    SET @OpDate = '2025-01-28';

    INSERT INTO @OrderBalance (
        Date, AutoID, Customer, Short, RefID, CodeID, BrandID, UnitID,
        Qty, Qty1, Qty2, Price, Weight, Sr, Remark
    )
    /* ---- Block 1: non-manufacturing (original behavior, fixed join) ---- */
    SELECT
        dbo.CastDate(H.Date),
        AutoID   = ISNULL(H.DocumentID, ''),
        Customer = C.Name,
        C.Short,
        tmp.RefID,
        tmp.CodeID,
        tmp.BrandID,
        tmp.UnitID,
        D.Qty,
        D.Qty1,
        D.Qty2,
        D.Price,
        D.Weight,
        D.Sr,
        D.Remark
    FROM (
        SELECT RefID, CodeID, BrandID, UnitID, Qty, Qty1, Qty2
        FROM SaleOrderDetail D
        JOIN SaleOrderHead H ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CustomerID = @CustomerID
          AND D.CodeID NOT IN (
              SELECT ID FROM Stock
              WHERE GroupID IN (
                  SELECT ID FROM StockGroup
                  WHERE ISNULL(Deleted, 0) <> 1 AND ISNULL(isManu, 0) = 1
              )
          )
        GROUP BY RefID, CodeID, BrandID, UnitID, Qty, Qty1, Qty2

        UNION ALL

        SELECT OrderRefID, CodeID, BrandID, UnitID, -Qty, Qty1, Qty2
        FROM SaleDetail D
        JOIN SaleHead H ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CustomerID = IIF(@CustomerID = 3496, H.CustomerID, @CustomerID)
          AND D.CodeID NOT IN (
              SELECT ID FROM Stock
              WHERE GroupID IN (
                  SELECT ID FROM StockGroup
                  WHERE ISNULL(Deleted, 0) <> 1 AND ISNULL(isManu, 0) = 1
              )
          )
        GROUP BY OrderRefID, CodeID, BrandID, UnitID, Qty, Qty1, Qty2
    ) tmp
    JOIN SaleOrderHead H ON tmp.RefID = H.ID
    JOIN SaleOrderDetail D
        ON  tmp.RefID   = D.RefID
        AND tmp.CodeID  = D.CodeID
        AND ISNULL(tmp.BrandID, -1) = ISNULL(D.BrandID, -1)
        AND tmp.UnitID  = D.UnitID
        AND ISNULL(tmp.Qty1, 0) = ISNULL(D.Qty1, 0)
        AND ISNULL(tmp.Qty2, 0) = ISNULL(D.Qty2, 0)
    JOIN Customer C ON C.ID = H.CustomerID
    WHERE ISNULL(H.Deleted, 0) <> 1
      AND ISNULL(H.isSales, 0) <> 1
    GROUP BY
        H.Date, H.DocumentID, C.Name, C.Short,
        tmp.RefID, tmp.CodeID, tmp.BrandID, tmp.UnitID,
        D.Price, D.Weight, D.Qty, D.Qty1, D.Qty2, D.Sr, D.Remark

    UNION ALL

    /* ---- Block 2: manufacturing (original behavior, fixed join) ---- */
    SELECT
        dbo.CastDate(H.Date),
        AutoID   = ISNULL(H.DocumentID, ''),
        Customer = C.Name,
        C.Short,
        tmp.RefID,
        tmp.CodeID,
        tmp.BrandID,
        tmp.UnitID,
        SUM(tmp.Qty),
        D.Qty1,
        D.Qty2,
        D.Price,
        D.Weight,
        D.Sr,
        D.Remark
    FROM (
        SELECT RefID, CodeID, BrandID, UnitID, Qty, Qty1, Qty2
        FROM SaleOrderDetail D
        JOIN SaleOrderHead H ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CustomerID = @CustomerID
          AND D.CodeID IN (
              SELECT ID FROM Stock
              WHERE GroupID IN (
                  SELECT ID FROM StockGroup
                  WHERE ISNULL(Deleted, 0) <> 1 AND ISNULL(isManu, 0) = 1
              )
          )
        GROUP BY RefID, CodeID, BrandID, UnitID, Qty, Qty1, Qty2

        UNION ALL

        SELECT OrderRefID, CodeID, BrandID, UnitID, -Qty, Qty1, Qty2
        FROM SaleDetail D
        JOIN SaleHead H ON H.ID = D.RefID
        WHERE ISNULL(H.Deleted, 0) <> 1
          AND H.CustomerID = IIF(@CustomerID = 3496, H.CustomerID, @CustomerID)
          AND D.CodeID IN (
              SELECT ID FROM Stock
              WHERE GroupID IN (
                  SELECT ID FROM StockGroup
                  WHERE ISNULL(Deleted, 0) <> 1 AND ISNULL(isManu, 0) = 1
              )
          )
        GROUP BY OrderRefID, CodeID, BrandID, UnitID, Qty, Qty1, Qty2
    ) tmp
    JOIN SaleOrderHead H ON tmp.RefID = H.ID
    JOIN SaleOrderDetail D
        ON  tmp.RefID   = D.RefID
        AND tmp.CodeID  = D.CodeID
        AND ISNULL(tmp.BrandID, -1) = ISNULL(D.BrandID, -1)
        AND tmp.UnitID  = D.UnitID
        AND ISNULL(tmp.Qty1, 0) = ISNULL(D.Qty1, 0)
        AND ISNULL(tmp.Qty2, 0) = ISNULL(D.Qty2, 0)
    JOIN Customer C ON C.ID = H.CustomerID
    WHERE ISNULL(H.Deleted, 0) <> 1
    GROUP BY
        H.Date, H.DocumentID, C.Name, C.Short,
        tmp.RefID, tmp.CodeID, tmp.BrandID, tmp.UnitID,
        D.Price, D.Weight, D.Qty1, D.Qty2, D.Sr, D.Remark
    HAVING SUM(tmp.Qty) > 0
       AND dbo.CastDate(H.Date) > '2025-12-19';

    RETURN;
END;
GO

/*
================================================================================
TEST QUERIES — run after deploy
================================================================================

-- 1) Customer 2609 (pplplst) — expect 4 rows for RefID 6481/6517
SELECT COUNT(*) AS RowCnt_2609 FROM dbo.GetSaleOrderBalSales(2609);

SELECT Date, AutoID, Short, RefID, CodeID, UnitID, Qty, Sr, Remark
FROM dbo.GetSaleOrderBalSales(2609)
WHERE RefID IN (6481, 6517)
ORDER BY RefID, Sr;
-- expect:
--   6481 / CodeID 3032 / Qty 10 / Sr 1
--   6517 / CodeID 1265 / Qty 1  / Sr 3
--   6517 / CodeID 10090 / Qty 20 / Sr 2
--   6517 / CodeID 10224 / Qty 20 / Sr 1

-- 2) Customer 3496 — expect 6 rows, CodeID 570 = 2 rows (no UnitID mix)
SELECT COUNT(*) AS RowCnt_3496 FROM dbo.GetSaleOrderBalSales(3496);

SELECT RefID, Sr, CodeID, UnitID, Qty, Price, Remark
FROM dbo.GetSaleOrderBalSales(3496)
WHERE CodeID = 570
ORDER BY Sr;

-- 3) Compare with List TVF (all customers)
SELECT COUNT(*) AS RowCnt_List FROM dbo.GetSaleOrderBalSalesList();

SELECT *
FROM dbo.GetSaleOrderBalSalesList()
WHERE Short = 'pplplst'
ORDER BY RefID, Sr;

-- 4) Mismatch check: rows in List for 2609 but not in per-customer TVF
SELECT L.*
FROM dbo.GetSaleOrderBalSalesList() L
WHERE L.Short = 'pplplst'
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.GetSaleOrderBalSales(2609) B
      WHERE B.RefID  = L.RefID
        AND B.Sr     = L.Sr
        AND B.CodeID = L.CodeID
        AND B.UnitID = L.UnitID
  );
-- expect 0 rows
*/
