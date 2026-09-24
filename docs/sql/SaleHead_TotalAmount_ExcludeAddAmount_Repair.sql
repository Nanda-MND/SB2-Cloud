/*
  One-time repair: SaleHead.TotalAmount that still includes AddAmount (bank fee).

  Detect: TotalAmount ≈ Amount - Discount + Tax + AddAmount
  Fix:    TotalAmount = Amount - Discount + TaxAmount

  Safe to re-run. Does not change AddAmount / Charges.
*/

USE [SB1];
GO

UPDATE dbo.SaleHead
SET TotalAmount = ISNULL(Amount, 0) - ISNULL(Discount, 0) + ISNULL(TaxAmount, 0)
WHERE ISNULL(Deleted, 0) <> 1
  AND ISNULL(AddAmount, 0) <> 0
  AND ISNULL(TotalAmount, 0) = ISNULL(Amount, 0) - ISNULL(Discount, 0) + ISNULL(TaxAmount, 0) + ISNULL(AddAmount, 0);

PRINT CONCAT('SaleHead TotalAmount repaired rows: ', @@ROWCOUNT);
GO
