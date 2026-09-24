/*
  Retry DeadLetter rows on LOCAL after Cloud SyncConfig fix.

  sqlcmd -S Server\SB1 -d SB1 -U sa -P xxx -C -I -i DataSync_20_RetryDeadLetter.sql
*/

SET NOCOUNT ON;
GO

DECLARE @Tables TABLE (TableName sysname PRIMARY KEY);
INSERT @Tables (TableName) VALUES
    (N'VoucherEditing'),
    (N'SalesID'),
    (N'UserRights');

UPDATE o SET
    Status = N'Pending',
    AttemptCount = 0,
    LastError = NULL
FROM dbo.SyncOutbox o
INNER JOIN @Tables t ON t.TableName = o.TableName
WHERE o.Direction = N'L2C' AND o.Status = N'DeadLetter';

PRINT 'Reset to Pending: ' + CAST(@@ROWCOUNT AS nvarchar(10));

SELECT Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox WHERE Direction = N'L2C'
GROUP BY Status ORDER BY Status;
GO
