/*
  Retry failed L2C outbox rows on LOCAL after Cloud SyncApply fix.
  Run on LOCAL (Server\SB1 / SB1).

  SyncOutbox columns: AttemptCount (not RetryCount), Status = DeadLetter|Conflict (not Failed).
*/

SET NOCOUNT ON;

DECLARE @n int;

UPDATE dbo.SyncOutbox
SET Status = N'Pending',
    LastError = NULL,
    AttemptCount = 0
WHERE Direction = N'L2C'
  AND Status IN (N'DeadLetter', N'Conflict')
  AND (
      LastError LIKE N'%IDENTITY_INSERT%'
      OR LastError LIKE N'%SyncApply_Generic%'
      OR LastError LIKE N'%no row updated or inserted%'
  );

SET @n = @@ROWCOUNT;
PRINT CAST(@n AS varchar(10)) + N' L2C outbox row(s) reset to Pending.';

SELECT TOP 20 OutboxID, TableName, Status, LastError, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C' AND Status = N'Pending'
ORDER BY OutboxID;

SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C'
GROUP BY Status
ORDER BY Status;
GO
