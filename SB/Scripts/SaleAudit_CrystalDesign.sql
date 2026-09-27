/*
  Crystal Design SQL — SaleEditDeleteLog.rpt (Format A, Portrait)
  =================================================================
  ActionDate = when user Edit/Delete (log time)
  OldDate/NewDate = invoice Date before/after
  OldCustomer/NewCustomer = customer name before/after

  Live DB: run SaleAudit_Alter_OldNewDateCustomer.sql first if columns missing.
*/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.vw_SaleEditDeleteLog_Crystal', N'V') IS NOT NULL
    DROP VIEW dbo.vw_SaleEditDeleteLog_Crystal;
GO

CREATE VIEW dbo.vw_SaleEditDeleteLog_Crystal
AS
SELECT
    AuditID         = H.ID,
    ActionDate      = H.ActionDate,
    ActionName      = CASE H.Action WHEN 'E' THEN N'Edit' WHEN 'D' THEN N'Delete' ELSE H.Action END,
    UserName        = ISNULL(U.Short, ISNULL(U.Name, N'')),
    AutoID          = ISNULL(H.AutoID, N''),
    DocumentID      = ISNULL(CONVERT(nvarchar(50), H.DocumentID), N''),
    OldDate         = ISNULL(H.OldDate, H.InvoiceDate),
    NewDate         = ISNULL(H.NewDate, H.InvoiceDate),
    OldCustomer     = ISNULL(OC.Name, N''),
    NewCustomer     = ISNULL(NC.Name, N''),
    Customer        = ISNULL(NC.Name, ISNULL(OC.Name, N'')),
    OldTotalAmount  = ISNULL(H.OldTotalAmount, 0),
    NewTotalAmount  = ISNULL(H.NewTotalAmount, 0),
    IsHeadOnly      = CASE WHEN D.ID IS NULL THEN 1 ELSE 0 END,
    Sr              = ISNULL(D.Sr, 0),
    LineActionName  = CASE D.LineAction
                        WHEN 'A' THEN N'Add'
                        WHEN 'U' THEN N'Update'
                        WHEN 'D' THEN N'Delete'
                        ELSE N''
                      END,
    Code            = ISNULL(S.Short, N''),
    Stock           = ISNULL(S.Name, N''),
    Unit            = ISNULL(UN.Name, N''),
    OldQty          = D.OldQty,
    NewQty          = D.NewQty,
    OldPrice        = D.OldPrice,
    NewPrice        = D.NewPrice,
    OldAmount       = D.OldAmount,
    NewAmount       = D.NewAmount,
    Amount          = ISNULL(D.NewAmount, ISNULL(D.OldAmount, 0))
FROM dbo.SaleAuditHead H
LEFT JOIN dbo.SaleAuditDetail D ON D.AuditID = H.ID
LEFT JOIN dbo.Customer OC ON OC.ID = ISNULL(H.OldCustomerID, H.CustomerID)
LEFT JOIN dbo.Customer NC ON NC.ID = ISNULL(H.NewCustomerID, H.CustomerID)
LEFT JOIN dbo.Users U ON U.ID = H.UserID
LEFT JOIN dbo.Stock S ON S.ID = D.CodeID
LEFT JOIN dbo.Unit UN ON UN.ID = D.UnitID;
GO

PRINT '[OK] vw_SaleEditDeleteLog_Crystal';
GO

/* ----- Head sample for Crystal ----- */
SELECT
    AuditID, ActionDate, ActionName, UserName,
    AutoID, DocumentID,
    OldDate, NewDate,
    OldCustomer, NewCustomer, Customer,
    OldTotalAmount, NewTotalAmount,
    IsHeadOnly, Sr, LineActionName,
    Code, Stock, Unit,
    OldQty, NewQty, OldPrice, NewPrice, OldAmount, NewAmount, Amount
FROM dbo.vw_SaleEditDeleteLog_Crystal
WHERE CAST(ActionDate AS date) BETWEEN DATEADD(DAY, -30, CAST(GETDATE() AS date)) AND CAST(GETDATE() AS date)
ORDER BY ActionDate DESC, AuditID, Sr;
GO

/* ----- Setting ----- */
SELECT CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo
FROM dbo.Setting WHERE ID = 1;
GO
