/*
  C2L sync test — Customer (Option C: master data only).

  Sale/Purchase C2L is OFF (DataSync_31). Test Customer, Location, Users — not vouchers.

  === STEP A — Cloud pre-check (SSMS → db_abbe78_warehouse) ===
  Run: Check-C2LStatus.sql
  Expect: Customer CaptureCloud = 1, tr_SyncOutbox_Customer exists

  === STEP B — Cloud: make a test edit ===
  Pick a customer ID both Cloud and Local have (same ID).
*/

SET NOCOUNT ON;

-- B1) Baseline (Cloud)
DECLARE @TestId int = (
    SELECT TOP 1 ID FROM dbo.Customer
    WHERE Deleted = 0 OR Deleted IS NULL
    ORDER BY ID
);

IF @TestId IS NULL
BEGIN
    PRINT 'No Customer row found on this database.';
    RETURN;
END

PRINT 'Test Customer ID = ' + CAST(@TestId AS varchar(20));

SELECT ID, Name, Address, SyncModifiedAt, SyncOrigin
FROM dbo.Customer WHERE ID = @TestId;

-- B2) Uncomment ONE line below to queue C2L (run on CLOUD only):
-- UPDATE dbo.Customer SET Name = LEFT(Name, 90) + N' [C2L-' + CONVERT(varchar(8), GETDATE(), 112) + N']' WHERE ID = @TestId;

PRINT '';
PRINT 'After UPDATE on Cloud, check outbox:';
SELECT TOP 5 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt, LastError
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND TableName = N'Customer'
ORDER BY OutboxID DESC;

GO

/*
  === STEP C — Office: pull ===
  SB.SyncAgent.exe /once
  (repeat 2-3 times, or run console mode until Cloud C2L Pending = 0)

  Log: look for "Pull failed" — should be none.

  === STEP D — Local verify (SSMS → Server\SB1 / SB1) ===
*/

-- D1) Same @TestId — Name should match Cloud after pull
DECLARE @TestId int = (
    SELECT TOP 1 ID FROM dbo.Customer
    WHERE Deleted = 0 OR Deleted IS NULL
    ORDER BY ID
);

SELECT ID, Name, SyncModifiedAt, SyncOrigin
FROM dbo.Customer WHERE ID = @TestId;

-- D2) Local should NOT have C2L outbox rows (capture is Cloud-only)
SELECT COUNT(*) AS LocalC2LRows
FROM dbo.SyncOutbox WHERE Direction = N'C2L';

GO
