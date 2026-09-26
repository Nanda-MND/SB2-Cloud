/*
  CLOUD ONLY (db_abe8c0_sb2).

  A hosting-panel restore copies Local's SyncOutbox onto Cloud.
  Direction=L2C rows on Cloud are that copy. The agent claims L2C only from Local,
  so Cloud L2C Pending never reaches 0.

  Mark restored L2C Pending/Syncing rows Synced. Do not delete PurchaseHead (or any
  business) rows. Do not touch Direction=C2L. Do not run on Local SB2 — that would
  skip the live L2C queue without applying it.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF DB_NAME() IN (N'SB2', N'SB1', N'SB', N'db_abbe78_warehouse', N'db_abe8c0_erp', N'db_abe8c0_luckyone')
   OR DB_NAME() LIKE N'%warehouse%'
   OR DB_NAME() LIKE N'%luckyone%'
   OR DB_NAME() LIKE N'%SB1%'
BEGIN
    RAISERROR(N'STOP: SB2_Close_RestoredCloud_L2C_Outbox is CLOUD ONLY. Refusing Local SB2 / SB1 / production.', 16, 1);
    RETURN;
END

IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NULL
BEGIN
    RAISERROR(N'dbo.SyncOutbox missing.', 16, 1);
    RETURN;
END

DECLARE @closed int;

UPDATE dbo.SyncOutbox
SET Status = N'Synced',
    SyncedAt = SYSUTCDATETIME(),
    LastError = N'Closed restored L2C copy; live L2C queue is Local.'
WHERE Direction = N'L2C'
  AND Status IN (N'Pending', N'Syncing');
SET @closed = @@ROWCOUNT;

PRINT N'Closed restored Cloud L2C Pending/Syncing: ' + CAST(@closed AS nvarchar(20));

SELECT Direction, Status, COUNT(*) AS Cnt
FROM dbo.SyncOutbox
WHERE Status IN (N'Pending', N'Syncing')
GROUP BY Direction, Status
ORDER BY Direction, Status;

PRINT N'C2L rows were not changed. Head rows were not deleted.';
GO
