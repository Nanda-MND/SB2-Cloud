/*
  FIX: DataSync_29 was run on LOCAL by mistake.

  DataSync_29 installs C2L capture (CaptureCloud=1, CaptureLocal=0) — wrong on Local.
  DataSync_10 on Local is OK — keep it (C2L apply proc).

  Run on LOCAL only:
    sqlcmd -S Server\SB1 -d SB1 -U sa -P ... -C -I -i DataSync_30_RestoreLocalL2C_AfterC2LMistake.sql

  Prerequisite: dbo.SyncInstall_Table exists (from DataSync_11_AllTables_Install.sql).
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.SyncInstall_Table', N'P') IS NULL
BEGIN
    RAISERROR(N'Run DataSync_11_AllTables_Install.sql on Local first.', 16, 1);
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

PRINT '=== BEFORE fix ===';
SELECT
    SUM(CASE WHEN CaptureLocal = 1 THEN 1 ELSE 0 END) AS CaptureLocalOn,
    SUM(CASE WHEN CaptureCloud = 1 THEN 1 ELSE 0 END) AS CaptureCloudOn,
    COUNT(*) AS TotalEnabled
FROM dbo.SyncConfig WHERE IsEnabled = 1;

SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox WHERE Direction = N'C2L'
GROUP BY Status;

-- 1) Remove wrong C2L queue rows on Local (Local should never produce C2L)
DELETE FROM dbo.SyncOutbox WHERE Direction = N'C2L';
PRINT 'Deleted Local C2L outbox rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

-- 2) Restore L2C capture triggers for all enabled tables (except 6 excludes)
DECLARE @t sysname, @ok int = 0, @err int = 0;

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
        EXEC dbo.SyncInstall_Table @TableName = @t, @InstallCapture = 1;
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

PRINT 'L2C capture restored: ' + CAST(@ok AS nvarchar(10)) + N', errors: ' + CAST(@err AS nvarchar(10));

-- 3) Re-apply disabled tables (CaptureLocal=0, drop triggers)
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @ExcludeTables;
OPEN cur;
FETCH NEXT FROM cur INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE dbo.SyncConfig SET IsEnabled = 0, CaptureLocal = 0, CaptureCloud = 0
    WHERE TableName = @t;
    IF OBJECT_ID(N'dbo.tr_SyncOutbox_' + @t, N'TR') IS NOT NULL
        EXEC(N'DROP TRIGGER dbo.tr_SyncOutbox_' + @t);
    FETCH NEXT FROM cur INTO @t;
END
CLOSE cur;
DEALLOCATE cur;

-- 4) Remove Cloud-only proc from Local (optional cleanup)
IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.SyncInstall_CloudCapture;
    PRINT 'Dropped SyncInstall_CloudCapture from Local.';
END

PRINT '=== AFTER fix ===';
SELECT
    SUM(CASE WHEN CaptureLocal = 1 THEN 1 ELSE 0 END) AS CaptureLocalOn,
    SUM(CASE WHEN CaptureCloud = 1 THEN 1 ELSE 0 END) AS CaptureCloudOn,
    COUNT(*) AS TotalEnabled
FROM dbo.SyncConfig WHERE IsEnabled = 1;

SELECT COUNT(*) AS L2C_Triggers FROM sys.triggers WHERE name LIKE N'tr_SyncOutbox_%';

SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox WHERE Direction = N'L2C'
GROUP BY Status ORDER BY Status;
GO
