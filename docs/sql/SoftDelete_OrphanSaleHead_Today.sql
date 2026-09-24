/*
  LOCAL (or Cloud) — soft-delete SaleHead for TODAY that have no SaleDetail.

  "Today" = Myanmar business date (same as ERP GetBusinessDateTime).
  Soft delete = Deleted=1 (+ IsDeleted/DeletedAt when columns exist).
  ERP filters use ISNULL(Deleted,0)<>1.

  Run STEP 1 first (preview). Set @Apply=1 only after the list looks right.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

DECLARE @Today date = CAST(
    (SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'Myanmar Standard Time'
    AS date);
DECLARE @Apply bit = 0;  -- 0 = preview only; 1 = soft-delete
DECLARE @ts datetime2(3) = SYSUTCDATETIME();

PRINT N'Today (Myanmar) = ' + CONVERT(nvarchar(10), @Today, 23);
PRINT N'@Apply = ' + CAST(@Apply AS nvarchar(1))
    + N' (0=preview, 1=soft-delete)';

IF OBJECT_ID(N'tempdb..#OrphanSaleHead') IS NOT NULL DROP TABLE #OrphanSaleHead;

SELECT
    h.ID,
    h.Date,
    h.AutoID,
    h.CustomerID,
    h.LocationID,
    h.UserID,
    h.TotalAmount,
    h.Deleted,
    DetailCnt = (
        SELECT COUNT(*) FROM dbo.SaleDetail d WHERE d.RefID = h.ID
    )
INTO #OrphanSaleHead
FROM dbo.SaleHead h
WHERE dbo.CastDate(h.Date) = @Today
  AND ISNULL(h.Deleted, 0) <> 1
  AND NOT EXISTS (
        SELECT 1
        FROM dbo.SaleDetail d
        WHERE d.RefID = h.ID
    );

PRINT N'=== Preview: SaleHead today with NO SaleDetail ===';
SELECT *
FROM #OrphanSaleHead
ORDER BY ID;

SELECT Cnt = COUNT(*), Ids = STRING_AGG(CAST(ID AS nvarchar(20)), N',')
FROM #OrphanSaleHead;

IF @Apply = 0
BEGIN
    PRINT N'Preview only. Re-run with @Apply = 1 to soft-delete.';
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM #OrphanSaleHead)
BEGIN
    PRINT N'Nothing to soft-delete.';
    RETURN;
END

BEGIN TRAN;

UPDATE h
SET h.Deleted = 1
FROM dbo.SaleHead h
INNER JOIN #OrphanSaleHead o ON o.ID = h.ID
WHERE ISNULL(h.Deleted, 0) <> 1;

IF COL_LENGTH(N'dbo.SaleHead', N'IsDeleted') IS NOT NULL
    UPDATE h
    SET h.IsDeleted = 1
    FROM dbo.SaleHead h
    INNER JOIN #OrphanSaleHead o ON o.ID = h.ID;

IF COL_LENGTH(N'dbo.SaleHead', N'DeletedAt') IS NOT NULL
    UPDATE h
    SET h.DeletedAt = @ts
    FROM dbo.SaleHead h
    INNER JOIN #OrphanSaleHead o ON o.ID = h.ID
    WHERE h.DeletedAt IS NULL;

IF COL_LENGTH(N'dbo.SaleHead', N'SyncModifiedAt') IS NOT NULL
    UPDATE h
    SET h.SyncModifiedAt = @ts
    FROM dbo.SaleHead h
    INNER JOIN #OrphanSaleHead o ON o.ID = h.ID;

COMMIT TRAN;

PRINT N'=== After soft-delete ===';
SELECT h.ID, h.Date, h.AutoID, h.Deleted,
       IsDeleted = CASE WHEN COL_LENGTH(N'dbo.SaleHead', N'IsDeleted') IS NOT NULL
                        THEN (SELECT IsDeleted FROM dbo.SaleHead x WHERE x.ID = h.ID)
                        ELSE NULL END
FROM dbo.SaleHead h
INNER JOIN #OrphanSaleHead o ON o.ID = h.ID
ORDER BY h.ID;

-- Remaining active orphans for today (should be 0)
SELECT Remaining = COUNT(*)
FROM dbo.SaleHead h
WHERE dbo.CastDate(h.Date) = @Today
  AND ISNULL(h.Deleted, 0) <> 1
  AND NOT EXISTS (SELECT 1 FROM dbo.SaleDetail d WHERE d.RefID = h.ID);

PRINT N'Done.';
GO
