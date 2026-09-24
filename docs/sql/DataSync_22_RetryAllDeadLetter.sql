/*
  Retry ALL DeadLetter rows on LOCAL (after Cloud SyncConfig fix).

  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -i DataSync_22_RetryAllDeadLetter.sql
*/

SET NOCOUNT ON;
GO

UPDATE dbo.SyncOutbox SET
    Status = N'Pending',
    AttemptCount = 0,
    LastError = NULL
WHERE Direction = N'L2C' AND Status = N'DeadLetter';

PRINT 'Reset to Pending: ' + CAST(@@ROWCOUNT AS nvarchar(10));

SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox WHERE Direction = N'L2C'
GROUP BY Status ORDER BY Status;
GO
