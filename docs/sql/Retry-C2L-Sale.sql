/*
  Retry C2L Sales after DataSync_10 insert fix.

  Run on CLOUD after redeploying DataSync_10 on LOCAL.

  Finds SaleHead/SaleDetail C2L rows marked Synced but missing on Local — reset to Pending.
  Or reset ALL Synced C2L Sale rows if @SaleHeadId is set.

  Set @SaleHeadId to your voucher ID, or NULL to retry recent Synced sale rows only.
*/

SET NOCOUNT ON;

DECLARE @SaleHeadId int = NULL;  -- e.g. 12345 — set to your Cloud SaleHead.ID

IF @SaleHeadId IS NOT NULL
BEGIN
    UPDATE dbo.SyncOutbox
    SET Status = N'Pending', AttemptCount = 0, LastError = NULL, SyncedAt = NULL
    WHERE Direction = N'C2L'
      AND TableName IN (N'SaleHead', N'SaleDetail')
      AND (
          (TableName = N'SaleHead' AND PrimaryKeyJson LIKE N'%"ID":' + CAST(@SaleHeadId AS nvarchar(20)) + N'%')
          OR (TableName = N'SaleDetail' AND PayloadJson LIKE N'%"RefID":' + CAST(@SaleHeadId AS nvarchar(20)) + N'%')
      );
    PRINT 'Reset rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));
END
ELSE
BEGIN
    UPDATE dbo.SyncOutbox
    SET Status = N'Pending', AttemptCount = 0, LastError = NULL, SyncedAt = NULL
    WHERE Direction = N'C2L'
      AND TableName IN (N'SaleHead', N'SaleDetail')
      AND Status = N'Synced'
      AND CreatedAt > DATEADD(day, -7, sysutcdatetime());
    PRINT 'Reset recent Synced sale C2L rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));
END

SELECT OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName IN (N'SaleHead', N'SaleDetail')
ORDER BY OutboxID DESC;
GO
