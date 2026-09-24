/*
  Disable sync for specific tables (Local SB1).
  - Turns off SyncConfig capture
  - Drops outbox triggers (stops new queue rows)
  - Removes Pending/Syncing/DeadLetter from SyncOutbox (agent stops pushing)

  EDIT @ExcludeTables below, then run in SSMS or sqlcmd.

  sqlcmd -S Server\SB1 -d SB1 -U sa -P YOUR_PASSWORD -C -I -i DataSync_18_DisableTables.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ========== EXCLUDED FROM CLOUD SYNC (client request) ==========
DECLARE @ExcludeTables TABLE (TableName sysname PRIMARY KEY);
INSERT @ExcludeTables (TableName) VALUES
    (N'GeneralLedgerDetail'),
    (N'stockInOutBalance'),
    (N'StockStartup'),
    (N'StockStatus'),
    (N'Tmp_StockOpening'),
    (N'UserStatus');
-- =================================================================

PRINT '=== Tables to disable ===';
SELECT TableName FROM @ExcludeTables ORDER BY TableName;

DECLARE @t sysname;
DECLARE @n int;

-- 1) SyncConfig off
UPDATE c SET IsEnabled = 0, CaptureLocal = 0, Notes = N'Disabled by DataSync_18 ' + CONVERT(nvarchar(30), sysutcdatetime(), 126)
FROM dbo.SyncConfig c
INNER JOIN @ExcludeTables e ON e.TableName = c.TableName;
SET @n = @@ROWCOUNT;
PRINT 'SyncConfig disabled: ' + CAST(@n AS nvarchar(10));

-- 2) Drop outbox + metadata triggers
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @ExcludeTables;
OPEN cur;
FETCH NEXT FROM cur INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.tr_SyncOutbox_' + @t, N'TR') IS NOT NULL
    BEGIN
        EXEC(N'DROP TRIGGER dbo.tr_SyncOutbox_' + @t);
        PRINT 'Dropped tr_SyncOutbox_' + @t;
    END
    IF OBJECT_ID(N'dbo.tr_' + @t + N'_SyncMetadata', N'TR') IS NOT NULL
    BEGIN
        EXEC(N'DROP TRIGGER dbo.tr_' + @t + N'_SyncMetadata');
        PRINT 'Dropped tr_' + @t + N'_SyncMetadata';
    END
    IF OBJECT_ID(N'dbo.tr_' + @t + N'_SoftDeleteSync', N'TR') IS NOT NULL
    BEGIN
        EXEC(N'DROP TRIGGER dbo.tr_' + @t + N'_SoftDeleteSync');
        PRINT 'Dropped tr_' + @t + N'_SoftDeleteSync';
    END
    IF OBJECT_ID(N'dbo.tr_SyncBlockDelete_' + @t, N'TR') IS NOT NULL
    BEGIN
        EXEC(N'DROP TRIGGER dbo.tr_SyncBlockDelete_' + @t);
        PRINT 'Dropped tr_SyncBlockDelete_' + @t;
    END
    FETCH NEXT FROM cur INTO @t;
END
CLOSE cur;
DEALLOCATE cur;

-- 3) Remove from outbox queue (keeps Synced history optional — delete all if preferred)
DELETE o
FROM dbo.SyncOutbox o
INNER JOIN @ExcludeTables e ON e.TableName = o.TableName
WHERE o.Direction = N'L2C' AND o.Status IN (N'Pending', N'Syncing', N'DeadLetter');
SET @n = @@ROWCOUNT;
PRINT 'Outbox rows removed (Pending/Syncing/DeadLetter): ' + CAST(@n AS nvarchar(10));

DELETE d FROM dbo.SyncDeadLetter d INNER JOIN @ExcludeTables e ON e.TableName = d.TableName;
PRINT 'SyncDeadLetter cleaned.';

PRINT '=== Remaining outbox summary ===';
SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox WHERE Direction = N'L2C'
GROUP BY Status ORDER BY Status;
GO
