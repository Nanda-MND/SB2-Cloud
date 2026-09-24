/*
  ============================================================================
  CLOUD — diagnose Detail Op=D apply (hard delete)
  ============================================================================
*/

SET NOCOUNT ON;
PRINT N'=== CLOUD Detail-delete apply diagnose ===';
PRINT N'DB=' + DB_NAME();

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'STOP: Local DB. Run on CLOUD warehouse.', 16, 1);
    RETURN;
END
GO

PRINT N'--- A) SyncApply_Generic markers ---';
SELECT
  CASE WHEN OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL THEN N'MISSING'
       WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) LIKE N'%hardDeleteDetail%'
            THEN N'OK_hardDeleteDetail'
       ELSE N'MISSING_hardDeleteDetail — run DataSync_10' END AS ApplyVer,
  CASE WHEN OBJECT_ID(N'dbo.SyncApply_PurchaseDetail', N'P') IS NULL THEN N'MISSING'
       WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_PurchaseDetail')) LIKE N'%@Operation%'
            THEN N'OK_has_@Operation'
       ELSE N'MISSING_@Operation — run Fix_SyncApply_AddOperation_Wrappers' END AS PurchaseDetailWrapper;
GO

PRINT N'--- B) Ghost soft-deleted details (UI still shows these) ---';
IF COL_LENGTH(N'dbo.PurchaseDetail', N'IsDeleted') IS NOT NULL
    SELECT COUNT(*) AS GhostIsDeleted1
    FROM dbo.PurchaseDetail WHERE ISNULL(IsDeleted,0) = 1;
ELSE
    PRINT N'No IsDeleted column.';
GO

PRINT N'--- C) Sample ghost rows ---';
IF COL_LENGTH(N'dbo.PurchaseDetail', N'IsDeleted') IS NOT NULL
    SELECT TOP 20 ID, RefID, Sr, CodeID, IsDeleted, SyncModifiedAt
    FROM dbo.PurchaseDetail
    WHERE ISNULL(IsDeleted,0) = 1
    ORDER BY ID DESC;
GO
