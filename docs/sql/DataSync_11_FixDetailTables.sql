/*
  Re-install sync for *Detail tables only (fix DELE truncation bug).
  Run AFTER updated DataSync_11_AllTables_Install.sql (nvarchar(30) fix).

  1. DataSync_11_AllTables_Install.sql  (update proc)
  2. This file
*/

SET NOCOUNT ON;

IF OBJECT_ID('dbo.SyncInstall_Table', 'P') IS NULL
BEGIN
    RAISERROR(N'Run DataSync_11_AllTables_Install.sql first.', 16, 1);
    RETURN;
END

DECLARE @t sysname, @n int = 0;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM sys.tables
    WHERE schema_id = SCHEMA_ID(N'dbo')
      AND name LIKE N'%Detail'
      AND name NOT LIKE N'Sync%'
    ORDER BY name;

OPEN c;
FETCH NEXT FROM c INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC dbo.SyncInstall_Table @TableName = @t, @InstallCapture = 1;
        SET @n += 1;
        PRINT N'OK: ' + @t;
    END TRY
    BEGIN CATCH
        PRINT N'WARN ' + @t + N': ' + ERROR_MESSAGE();
    END CATCH
    FETCH NEXT FROM c INTO @t;
END
CLOSE c;
DEALLOCATE c;

PRINT N'Detail tables reinstalled: ' + CAST(@n AS nvarchar(10));
GO

SELECT name FROM sys.triggers
WHERE name LIKE N'tr_SyncOutbox_%Detail'
ORDER BY name;
GO
