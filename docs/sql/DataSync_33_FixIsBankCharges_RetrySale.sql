/*
  Fix L2C DeadLetter: NULL into Cloud SaleHead.IsBankCharges

  Status UI: Agent Running, Cloud Online, Dead letter (IsBankCharges NULL).

  Run order:
    1) CLOUD  — this file section A (ensure column + DEFAULT)
    2) CLOUD  — re-run DataSync_10_SyncApply_Generic.sql  (ISNULL for NOT NULL bit)
    3) LOCAL — this file section B (retry SaleHead DeadLetter → Pending)

  Do not stop Sync Agent.
*/

SET NOCOUNT ON;
GO

/* ========== A) CLOUD ONLY ========== */
PRINT '=== A. Cloud SaleHead.IsBankCharges ===';

IF COL_LENGTH(N'dbo.SaleHead', N'IsBankCharges') IS NULL
BEGIN
    ALTER TABLE dbo.SaleHead ADD IsBankCharges bit NOT NULL
        CONSTRAINT DF_SaleHead_IsBankCharges DEFAULT (0);
    PRINT 'Added IsBankCharges NOT NULL DEFAULT 0';
END
ELSE
BEGIN
    IF EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.SaleHead')
          AND name = N'IsBankCharges' AND is_nullable = 1
    )
    BEGIN
        UPDATE dbo.SaleHead SET IsBankCharges = 0 WHERE IsBankCharges IS NULL;
        ALTER TABLE dbo.SaleHead ALTER COLUMN IsBankCharges bit NOT NULL;
        PRINT 'Backfilled NULLs + set NOT NULL';
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.default_constraints dc
        INNER JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
        WHERE dc.parent_object_id = OBJECT_ID(N'dbo.SaleHead') AND c.name = N'IsBankCharges'
    )
    BEGIN
        ALTER TABLE dbo.SaleHead
            ADD CONSTRAINT DF_SaleHead_IsBankCharges DEFAULT (0) FOR IsBankCharges;
        PRINT 'Added DEFAULT (0)';
    END
    ELSE
        PRINT 'IsBankCharges already present with DEFAULT';
END

SELECT c.name, t.name AS TypeName, c.is_nullable,
       dc.name AS DefaultConstraint
FROM sys.columns c
INNER JOIN sys.types t ON t.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc
    ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID(N'dbo.SaleHead') AND c.name = N'IsBankCharges';

PRINT '';
PRINT 'Next on CLOUD: run docs/sql/DataSync_10_SyncApply_Generic.sql';
PRINT 'Then on LOCAL: run section B below (or whole file if Local — skip if column already OK).';
GO

/* ========== B) LOCAL ONLY — retry SaleHead dead letters ========== */
PRINT '=== B. Local retry SaleHead DeadLetter ===';

IF DB_NAME() LIKE N'%warehouse%' OR DB_NAME() LIKE N'%cloud%'
BEGIN
    PRINT 'Skip retry on Cloud DB — run section B on Local SB1.';
END
ELSE
BEGIN
    UPDATE dbo.SyncOutbox SET
        Status = N'Pending',
        AttemptCount = 0,
        LastError = NULL
    WHERE Direction = N'L2C'
      AND Status = N'DeadLetter'
      AND TableName = N'SaleHead';

    PRINT 'SaleHead DeadLetter → Pending: ' + CAST(@@ROWCOUNT AS nvarchar(10));

    SELECT Status, COUNT(*) AS Cnt
    FROM dbo.SyncOutbox
    WHERE Direction = N'L2C' AND TableName = N'SaleHead'
    GROUP BY Status
    ORDER BY Status;

    SELECT TOP 10 OutboxID, Status, LEFT(ISNULL(LastError, N''), 100) AS LastError, CreatedAt
    FROM dbo.SyncOutbox
    WHERE Direction = N'L2C' AND TableName = N'SaleHead'
    ORDER BY OutboxID DESC;
END
GO
