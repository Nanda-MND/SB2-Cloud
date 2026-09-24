/*
  Fix Sale identity after Local wrote into Cloud ID zone (2e9+).

  Live may have many mistaken Local rows (not just 4) — use MAX(ID) + reserve.

  === STEP 1 — LOCAL (SB1): diagnose + fix Local seed ===
*/

SET NOCOUNT ON;
DECLARE @CloudFloor bigint = 2000000000;
DECLARE @Reserve    bigint = 100;  -- skip at least this many after floor / after max

PRINT '=== STEP 1 LOCAL: ' + DB_NAME() + ' ===';

SELECT
    CASE WHEN ID < @CloudFloor THEN N'LOCAL_ZONE'
         WHEN ID = @CloudFloor THEN N'CLOUD_OR_FIRST'
         ELSE N'HIGH_ZONE' END AS Kind,
    COUNT(*) AS Cnt,
    MIN(ID) AS MinId,
    MAX(ID) AS MaxId
FROM dbo.SaleHead
GROUP BY CASE WHEN ID < @CloudFloor THEN N'LOCAL_ZONE'
              WHEN ID = @CloudFloor THEN N'CLOUD_OR_FIRST'
              ELSE N'HIGH_ZONE' END;

DECLARE @maxLocalZone bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleHead WHERE ID < @CloudFloor);
DECLARE @maxHighZone bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleHead WHERE ID >= @CloudFloor);
DECLARE @maxLocalDetailZone bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleDetail WHERE ID < @CloudFloor);
DECLARE @maxHighDetail bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleDetail WHERE ID >= @CloudFloor);

PRINT 'LOCAL_ZONE max SaleHead   = ' + CAST(@maxLocalZone AS nvarchar(20));
PRINT 'HIGH_ZONE  max SaleHead   = ' + CAST(@maxHighZone AS nvarchar(20))
    + N'  << copy this for Cloud STEP 2';
PRINT 'HIGH_ZONE  max SaleDetail = ' + CAST(@maxHighDetail AS nvarchar(20));

IF @maxLocalZone <= 0
BEGIN
    RAISERROR(N'No SaleHead below CloudFloor — investigate before RESEED.', 16, 1);
    RETURN;
END

-- Local next inserts back in low zone
DBCC CHECKIDENT (N'dbo.SaleHead', RESEED, @maxLocalZone);
DBCC CHECKIDENT (N'dbo.SaleDetail', RESEED, @maxLocalDetailZone);

SELECT
    IDENT_CURRENT(N'dbo.SaleHead') AS SaleHeadIdent,
    IDENT_CURRENT(N'dbo.SaleDetail') AS SaleDetailIdent;

PRINT '';
PRINT 'Next Local Sale ~= ' + CAST(@maxLocalZone + 1 AS nvarchar(20));
PRINT 'Do NOT delete HIGH_ZONE rows.';
PRINT 'Then STEP 2 on CLOUD — set @LocalHighMaxSaleHead to HIGH_ZONE max above.';
GO

/*
  === STEP 2 — CLOUD: bump seed past Local high-zone MAX + reserve ===

  Edit @LocalHighMaxSaleHead / @LocalHighMaxSaleDetail from STEP 1 printout.
*/

SET NOCOUNT ON;
DECLARE @CloudFloor bigint = 2000000000;
DECLARE @Reserve    bigint = 100;

-- >>> PASTE from Local STEP 1 (HIGH_ZONE max) <<<
DECLARE @LocalHighMaxSaleHead   bigint = 2000000100;  -- change me
DECLARE @LocalHighMaxSaleDetail bigint = 2000000100;  -- change me

PRINT '=== STEP 2 CLOUD: ' + DB_NAME() + ' ===';

DECLARE @maxCloudHead bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleHead WHERE ID >= @CloudFloor);
DECLARE @maxCloudDetail bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleDetail WHERE ID >= @CloudFloor);

DECLARE @safeHead bigint = @CloudFloor;
IF @maxCloudHead > @safeHead SET @safeHead = @maxCloudHead;
IF @LocalHighMaxSaleHead > @safeHead SET @safeHead = @LocalHighMaxSaleHead;
IF @safeHead < @CloudFloor + @Reserve SET @safeHead = @CloudFloor + @Reserve;

DECLARE @safeDetail bigint = @CloudFloor;
IF @maxCloudDetail > @safeDetail SET @safeDetail = @maxCloudDetail;
IF @LocalHighMaxSaleDetail > @safeDetail SET @safeDetail = @LocalHighMaxSaleDetail;
IF @safeDetail < @CloudFloor + @Reserve SET @safeDetail = @CloudFloor + @Reserve;

PRINT 'Cloud SaleHead   RESEED to ' + CAST(@safeHead AS nvarchar(20))
    + N' → next ~' + CAST(@safeHead + 1 AS nvarchar(20));
PRINT 'Cloud SaleDetail RESEED to ' + CAST(@safeDetail AS nvarchar(20))
    + N' → next ~' + CAST(@safeDetail + 1 AS nvarchar(20));

DBCC CHECKIDENT (N'dbo.SaleHead', RESEED, @safeHead);
DBCC CHECKIDENT (N'dbo.SaleDetail', RESEED, @safeDetail);

SELECT
    IDENT_CURRENT(N'dbo.SaleHead') AS SaleHeadIdent,
    IDENT_CURRENT(N'dbo.SaleDetail') AS SaleDetailIdent;

PRINT 'Cloud next Sale should clear Local mistaken high IDs + 100 reserve.';
GO
