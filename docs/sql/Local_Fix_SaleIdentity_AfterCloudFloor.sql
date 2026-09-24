/*
  LOCAL ONLY — Fix Sale identity if Local RESEED accidentally hit Cloud floor (2e9).

  Symptom: Local ERP new SaleHead.ID >= 2000000000

  Causes:
    A) Accidental Cloud RESEED script run on Local
    B) C2L SyncApply IDENTITY_INSERT of Cloud IDs (>=2e9) bumps IDENT_CURRENT
       (fixed in DataSync_10_SyncApply_Generic — reseed after C2L high insert)

  Safe plan:
    1) Diagnose
    2) RESEED Local back to MAX(ID) where ID < CloudFloor (local zone)
    3) Do NOT delete rows with ID >= CloudFloor (may be real C2L from Cloud)
    4) Never run Cloud_Reseed script on Local again
    5) Redeploy DataSync_10_SyncApply_Generic.sql on LOCAL so C2L does not re-bump

  Run on: Server\SB1 / SB1 (office Local)
*/

SET NOCOUNT ON;

DECLARE @CloudFloor bigint = 2000000000;

PRINT '=== DB: ' + DB_NAME() + ' ===';
PRINT 'This script is for LOCAL only.';

-- 1) Diagnose
PRINT '=== 1. Identity vs zones ===';
SELECT
    IDENT_CURRENT(N'dbo.SaleHead')   AS SaleHead_IdentCurrent,
    IDENT_CURRENT(N'dbo.SaleDetail') AS SaleDetail_IdentCurrent;

SELECT
    COUNT(*) AS Cnt,
    MIN(ID) AS MinId,
    MAX(ID) AS MaxId,
    CASE WHEN ID >= @CloudFloor THEN N'CLOUD_ZONE' ELSE N'LOCAL_ZONE' END AS Zone
FROM dbo.SaleHead
GROUP BY CASE WHEN ID >= @CloudFloor THEN N'CLOUD_ZONE' ELSE N'LOCAL_ZONE' END;

-- Optional origin (if column exists)
IF COL_LENGTH(N'dbo.SaleHead', N'SyncOrigin') IS NOT NULL
BEGIN
    PRINT '=== SaleHead by SyncOrigin (1=Local, 2=Cloud) in CLOUD_ZONE ===';
    SELECT SyncOrigin, COUNT(*) AS Cnt, MIN(ID) AS MinId, MAX(ID) AS MaxId
    FROM dbo.SaleHead
    WHERE ID >= @CloudFloor
    GROUP BY SyncOrigin;
END

DECLARE @maxLocalHead bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleHead WHERE ID < @CloudFloor);
DECLARE @maxLocalDetail bigint =
    (SELECT ISNULL(MAX(CAST(ID AS bigint)), 0) FROM dbo.SaleDetail WHERE ID < @CloudFloor);

PRINT 'MAX local-zone SaleHead.ID   = ' + CAST(@maxLocalHead AS nvarchar(20));
PRINT 'MAX local-zone SaleDetail.ID = ' + CAST(@maxLocalDetail AS nvarchar(20));

IF @maxLocalHead <= 0
BEGIN
    RAISERROR(N'No SaleHead rows below CloudFloor — investigate before RESEED.', 16, 1);
    RETURN;
END

-- 2) RESEED Local back into local zone (next insert = max+1)
PRINT '=== 2. RESEED Local SaleHead / SaleDetail ===';
DBCC CHECKIDENT (N'dbo.SaleHead', RESEED, @maxLocalHead);
DBCC CHECKIDENT (N'dbo.SaleDetail', RESEED, @maxLocalDetail);

PRINT 'After RESEED:';
SELECT
    IDENT_CURRENT(N'dbo.SaleHead')   AS SaleHead_IdentCurrent,
    IDENT_CURRENT(N'dbo.SaleDetail') AS SaleDetail_IdentCurrent;

PRINT '';
PRINT 'Next Local Sale should get ID = local MAX + 1 (still << 2e9).';
PRINT 'Rows already saved with ID >= 2e9 stay as-is (C2L or mistaken local).';
PRINT 'Do NOT run Cloud_Reseed_TransactionIdRanges.sql on Local.';
GO
