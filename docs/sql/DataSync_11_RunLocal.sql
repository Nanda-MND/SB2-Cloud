/*
  Install sync on ALL eligible tables — LOCAL (capture triggers ON).

  PREREQUISITE: run DataSync_11_AllTables_Install.sql FIRST (creates dbo.SyncInstall_Table).
*/

SET NOCOUNT ON;

IF OBJECT_ID('dbo.SyncInstall_Table', 'P') IS NULL
BEGIN
    RAISERROR(N'Missing dbo.SyncInstall_Table. Run DataSync_11_AllTables_Install.sql first, then re-run this file.', 16, 1);
    RETURN;
END

DECLARE @InstallCapture bit = 1;
DECLARE @t sysname;
DECLARE @cnt int = 0;

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.name
    FROM sys.tables t
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = N'dbo'
      AND t.name NOT LIKE N'Sync%'
      AND t.name NOT IN (N'sysdiagrams', N'dtproperties', N'__EFMigrationsHistory', N'__MigrationHistory')
      AND EXISTS (
          SELECT 1 FROM sys.indexes i
          WHERE i.object_id = t.object_id AND i.is_primary_key = 1
          GROUP BY i.object_id
          HAVING COUNT(*) = 1
      )
    ORDER BY t.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC dbo.SyncInstall_Table @TableName = @t, @InstallCapture = @InstallCapture;
        SET @cnt += 1;
    END TRY
    BEGIN CATCH
        PRINT N'WARN: SyncInstall_Table failed for ' + @t + N': ' + ERROR_MESSAGE();
    END CATCH
    FETCH NEXT FROM table_cursor INTO @t;
END
CLOSE table_cursor;
DEALLOCATE table_cursor;

PRINT N'SyncInstall_AllTables (Local) completed. Tables processed: ' + CAST(@cnt AS nvarchar(10));
GO
