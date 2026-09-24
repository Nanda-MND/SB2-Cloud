/*
  Post-restore reset — run on LOCAL after Cloud restore + Cloud cleanup

  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -i LocalToCloudRestore_03_Local_ResetOutbox.sql
*/

SET NOCOUNT ON;
GO

PRINT '=== Local post-restore outbox reset ===';

DECLARE @before int = (SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Direction = N'L2C');

DELETE FROM dbo.SyncOutbox WHERE Direction = N'L2C';
DELETE FROM dbo.SyncDeadLetter;

PRINT 'Removed L2C outbox rows: ' + CAST(@before AS nvarchar(20));

MERGE dbo.SyncState AS t
USING (VALUES (N'CloudOnline', N'1'), (N'LastCloudRestore', CONVERT(nvarchar(30), sysutcdatetime(), 126)))
    AS s(StateKey, StateValue)
ON t.StateKey = s.StateKey
WHEN MATCHED THEN UPDATE SET StateValue = s.StateValue, UpdatedAt = sysutcdatetime()
WHEN NOT MATCHED THEN INSERT (StateKey, StateValue) VALUES (s.StateKey, s.StateValue);

SELECT Status, COUNT(*) AS Cnt FROM dbo.SyncOutbox WHERE Direction = N'L2C' GROUP BY Status;
GO
