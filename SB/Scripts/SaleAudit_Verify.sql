/*
  Quick check after deploy / after a test edit or delete.
*/
SET NOCOUNT ON;

SELECT Item = N'SaleAuditHead rows', Cnt = COUNT(*) FROM dbo.SaleAuditHead
UNION ALL
SELECT N'SaleAuditDetail rows', COUNT(*) FROM dbo.SaleAuditDetail;

SELECT TOP 50 *
FROM dbo.vw_SaleAuditLog
ORDER BY ActionDate DESC, AuditID DESC, Sr;
GO
