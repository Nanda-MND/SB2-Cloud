/*======================================================================
  OPTIONAL one-time repair:
  Old rows may have TotalAmount = goods + bank fee.
  Correct rule: TotalAmount = goods net only (Amount - Discount + Tax).
  AddAmount holds the bank fee separately.
======================================================================*/
SET NOCOUNT ON;

/* Preview (uncomment to inspect):
SELECT ID, AutoID, Amount, Discount, TaxAmount, AddAmount, TotalAmount,
       Expected = ISNULL(Amount,0) - ISNULL(Discount,0) + ISNULL(TaxAmount,0)
FROM dbo.SaleHead
WHERE ISNULL(Deleted,0) <> 1
  AND ISNULL(AddAmount,0) <> 0
  AND ISNULL(TotalAmount,0) = ISNULL(Amount,0) - ISNULL(Discount,0) + ISNULL(TaxAmount,0) + ISNULL(AddAmount,0);
*/

UPDATE dbo.SaleHead
SET TotalAmount = ISNULL(Amount,0) - ISNULL(Discount,0) + ISNULL(TaxAmount,0)
WHERE ISNULL(Deleted,0) <> 1
  AND ISNULL(AddAmount,0) <> 0
  AND ISNULL(TotalAmount,0) = ISNULL(Amount,0) - ISNULL(Discount,0) + ISNULL(TaxAmount,0) + ISNULL(AddAmount,0);

PRINT '[OK] Repaired SaleHead.TotalAmount rows = ' + CAST(@@ROWCOUNT AS varchar(20));
GO
