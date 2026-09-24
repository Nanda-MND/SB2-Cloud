/*
  C2L sync status — run on CLOUD and LOCAL.

  Cloud: sqlcmd -S SQL1002.site4now.net -d db_abbe78_warehouse -U ... -i Check-C2LStatus.sql
  Local: sqlcmd -S Server\SB1 -d SB1 -U sa -P ... -i Check-C2LStatus.sql
*/

SET NOCOUNT ON;

PRINT '=== DB: ' + DB_NAME() + ' ===';

PRINT '=== C2L-enabled tables ===';
SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud, Priority
FROM dbo.SyncConfig
WHERE CaptureCloud = 1 OR EXISTS (
    SELECT 1 FROM sys.triggers tr
    JOIN sys.tables tb ON tb.object_id = tr.parent_id
    WHERE tr.name = N'tr_SyncOutbox_' + TableName
)
ORDER BY TableName;

PRINT '=== Outbox C2L summary ===';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
    SELECT Status, COUNT(*) AS Cnt
    FROM dbo.SyncOutbox WHERE Direction = N'C2L'
    GROUP BY Status ORDER BY Status;
ELSE
    PRINT 'No SyncOutbox';

PRINT '=== C2L errors (last 5) ===';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
    SELECT TOP 5 OutboxID, TableName, Status, LEFT(LastError, 100) AS LastError
    FROM dbo.SyncOutbox
    WHERE Direction = N'C2L' AND LastError IS NOT NULL
    ORDER BY OutboxID DESC;

PRINT '=== Conflict log (C2L) ===';
IF OBJECT_ID(N'dbo.SyncConflictLog', N'U') IS NOT NULL
    SELECT TOP 5 TableName, Resolution, DetectedAt, LEFT(Message, 80) AS Message
    FROM dbo.SyncConflictLog WHERE Direction = N'C2L'
    ORDER BY DetectedAt DESC;
GO
