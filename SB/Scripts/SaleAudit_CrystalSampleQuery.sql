/*
  Sample result set for Crystal design of SaleEditDeleteLog.rpt.
  Run on SB2 after audit tables exist; use columns as Head fields.
*/
SET NOCOUNT ON;

SELECT TOP 50
    AuditID = H.ID,
    ActionDate = H.ActionDate,
    ActionName = CASE H.Action WHEN 'E' THEN N'Edit' WHEN 'D' THEN N'Delete' ELSE H.Action END,
    UserName = ISNULL(U.Short, ISNULL(U.Name, N'')),
    AutoID = ISNULL(H.AutoID, N''),
    DocumentID = ISNULL(CONVERT(nvarchar(50), H.DocumentID), N''),
    Customer = ISNULL(C.Name, N''),
    OldTotalAmount = ISNULL(H.OldTotalAmount, 0),
    NewTotalAmount = ISNULL(H.NewTotalAmount, 0),
    IsHeadOnly = CASE WHEN D.ID IS NULL THEN 1 ELSE 0 END,
    Sr = ISNULL(D.Sr, 0),
    LineActionName = CASE D.LineAction WHEN 'A' THEN N'Add' WHEN 'U' THEN N'Update' WHEN 'D' THEN N'Delete' ELSE N'' END,
    Code = ISNULL(S.Short, N''),
    Stock = ISNULL(S.Name, N''),
    Unit = ISNULL(UN.Name, N''),
    OldQty = D.OldQty,
    NewQty = D.NewQty,
    OldPrice = D.OldPrice,
    NewPrice = D.NewPrice,
    OldAmount = D.OldAmount,
    NewAmount = D.NewAmount,
    Amount = ISNULL(D.NewAmount, ISNULL(D.OldAmount, 0))
FROM dbo.SaleAuditHead H
LEFT JOIN dbo.SaleAuditDetail D ON D.AuditID = H.ID
LEFT JOIN dbo.Customer C ON C.ID = H.CustomerID
LEFT JOIN dbo.Users U ON U.ID = H.UserID
LEFT JOIN dbo.Stock S ON S.ID = D.CodeID
LEFT JOIN dbo.Unit UN ON UN.ID = D.UnitID
ORDER BY H.ActionDate DESC, H.ID, D.Sr;
GO
