/*
  Enable C2L capture on CLOUD for ALL synced tables (mirror L2C scope).

  Use case: Home → Cloud insert/update → Office agent pulls → Local DB.

  Prerequisite: Run DataSync_28_EnableC2L_Capture.sql first (creates SyncInstall_CloudCapture).

  Excludes same tables as DataSync_18_DisableTables.sql (no sync either direction).

  sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U db_abbe78_warehouse_admin -P xxx -C -I -i DataSync_29_EnableAllC2L_Capture.sql
*/

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
BEGIN
    RAISERROR(N'Run DataSync_28_EnableC2L_Capture.sql first (creates SyncInstall_CloudCapture).', 16, 1);
    RETURN;
END
GO

DECLARE @ExcludeTables TABLE (TableName sysname PRIMARY KEY);
INSERT @ExcludeTables (TableName) VALUES
    (N'GeneralLedgerDetail'),
    (N'stockInOutBalance'),
    (N'StockStartup'),
    (N'StockStatus'),
    (N'Tmp_StockOpening'),
    (N'UserStatus');

PRINT '=== Install C2L capture for all enabled tables ===';

DECLARE @t sysname, @ok int = 0, @skip int = 0, @err int = 0;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT c.TableName
    FROM dbo.SyncConfig c
    WHERE c.IsEnabled = 1
      AND NOT EXISTS (SELECT 1 FROM @ExcludeTables e WHERE e.TableName = c.TableName)
      AND OBJECT_ID(N'dbo.' + c.TableName, N'U') IS NOT NULL
    ORDER BY c.Priority, c.TableName;

OPEN c;
FETCH NEXT FROM c INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC dbo.SyncInstall_CloudCapture @TableName = @t;
        SET @ok += 1;
    END TRY
    BEGIN CATCH
        PRINT N'WARN ' + @t + N': ' + ERROR_MESSAGE();
        SET @err += 1;
    END CATCH
    FETCH NEXT FROM c INTO @t;
END
CLOSE c;
DEALLOCATE c;

PRINT 'C2L installed: ' + CAST(@ok AS nvarchar(10)) + N', errors: ' + CAST(@err AS nvarchar(10));

PRINT '=== Verify ===';
SELECT
    SUM(CASE WHEN CaptureCloud = 1 THEN 1 ELSE 0 END) AS CaptureCloudOn,
    SUM(CASE WHEN CaptureLocal = 1 THEN 1 ELSE 0 END) AS CaptureLocalOn,
    COUNT(*) AS TotalEnabled
FROM dbo.SyncConfig WHERE IsEnabled = 1;

SELECT COUNT(*) AS C2LTriggers FROM sys.triggers WHERE name LIKE N'tr_SyncOutbox_%';

SELECT TOP 10 TableName, IsEnabled, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig WHERE CaptureCloud = 1 ORDER BY TableName;
GO
