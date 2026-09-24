/*
  Enable sync for Manufacturing tables on LOCAL.
  Run on Server\SB1 / SB1 BEFORE SyncSeed_Table.

  Requires: DataSync_11_AllTables_Install.sql already run once
  (creates dbo.SyncInstall_Table).
*/

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.SyncInstall_Table', 'P') IS NULL
BEGIN
    RAISERROR(N'Run DataSync_11_AllTables_Install.sql first.', 16, 1);
    RETURN;
END
GO

DECLARE @t sysname, @p tinyint;
DECLARE @tables TABLE (TableName sysname, Priority tinyint);
INSERT @tables VALUES
    (N'RawIssueHead', 40), (N'RawIssueDetail', 45),
    (N'FinishGoodsHead', 40), (N'FinishGoodsDetail', 45);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, Priority FROM @tables;

OPEN c;
FETCH NEXT FROM c INTO @t, @p;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.' + @t, N'U') IS NULL
        PRINT N'MISSING TABLE: ' + @t;
    ELSE
    BEGIN
        EXEC dbo.SyncInstall_Table @TableName = @t, @InstallCapture = 1, @Priority = @p;
        PRINT N'ENABLED: ' + @t;
    END
    FETCH NEXT FROM c INTO @t, @p;
END
CLOSE c;
DEALLOCATE c;
GO

PRINT '=== Verify ===';
SELECT TableName, IsEnabled, CaptureLocal, Priority
FROM dbo.SyncConfig
WHERE TableName IN (N'RawIssueHead', N'RawIssueDetail', N'FinishGoodsHead', N'FinishGoodsDetail');

SELECT name AS TriggerName
FROM sys.triggers
WHERE name IN (
    N'tr_SyncOutbox_RawIssueHead', N'tr_SyncOutbox_RawIssueDetail',
    N'tr_SyncOutbox_FinishGoodsHead', N'tr_SyncOutbox_FinishGoodsDetail'
);
GO

PRINT 'Next: seed rows';
PRINT '  EXEC dbo.SyncSeed_Table @TableName=N''RawIssueHead'', @BatchSize=200, @SkipIfOutboxExists=0;';
GO
