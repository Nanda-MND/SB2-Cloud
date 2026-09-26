/*
  =============================================================================
  LIVE DB — Sale Edit/Delete Audit (one-click)
  =============================================================================
  SSMS: enable SQLCMD Mode (Query > SQLCMD Mode), then run this file.
  Or run the child scripts one-by-one in order (no SQLCMD needed).

  Order:
    1) SaleAudit_Tables.sql
    2) SaleAudit_ReportMenu.sql
    3) Verify section below

  After SQL:
    - Rebuild SB.exe and deploy to clients
    - Copy SB\Reports\*.rpt if needed (reuses SaleByItemDetail.rpt)
    - Do NOT overwrite client DBConnection.ini
  =============================================================================
*/
SET NOCOUNT ON;
PRINT '=== 1) SaleAudit_Tables ===';
:r SaleAudit_Tables.sql
PRINT '=== 2) SaleAudit_ReportMenu ===';
:r SaleAudit_ReportMenu.sql
GO

PRINT '=== 3) Verify ===';
SELECT Step = 1, Item = N'SaleAuditHead',
       Status = CASE WHEN OBJECT_ID(N'dbo.SaleAuditHead', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 2, N'SaleAuditDetail',
       CASE WHEN OBJECT_ID(N'dbo.SaleAuditDetail', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 3, N'vw_SaleAuditLog',
       CASE WHEN OBJECT_ID(N'dbo.vw_SaleAuditLog', N'V') IS NOT NULL THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 4, N'ReportName 1160',
       CASE WHEN EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1160) THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 5, N'ReportName 1161',
       CASE WHEN EXISTS (SELECT 1 FROM dbo.ReportName WHERE ID = 1161) THEN N'OK' ELSE N'MISSING' END
UNION ALL SELECT 6, N'MenuSub 1161',
       CASE WHEN EXISTS (SELECT 1 FROM dbo.MenuSub WHERE TypeID = 3 AND MenuID = 1161 AND ISNULL(Deleted,0) = 0)
            THEN N'OK' ELSE N'MISSING' END
ORDER BY Step;
GO

PRINT '[DONE] 00_SaleAudit_All — rebuild/deploy SB.exe next';
GO
