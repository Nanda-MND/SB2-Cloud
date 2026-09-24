/*
  Fix L2C DeadLetter: NULL into Cloud IncomeExpenseHead.PrintCheque

  After SaleHead IsBankCharges cleared, Sync Status may show:
    Dead letter: 3
    Last error: Cannot insert NULL into column 'PrintCheque' ... IncomeExpenseHead

  Same root cause as IsBankCharges — NOT NULL bit + missing JSON.
  SyncApply_Generic (DataSync_10) already ISNULL(...,0) for NOT NULL bit —
  deploy that on Cloud first if not done, then retry here.

  Run order:
    1) CLOUD — section A (ensure PrintCheque + DEFAULT)
    2) CLOUD — DataSync_10_SyncApply_Generic.sql (if not already after IsBankCharges fix)
    3) LOCAL — section B (retry IncomeExpenseHead DeadLetter → Pending)
*/

SET NOCOUNT ON;
GO

/* ========== A) CLOUD ONLY ========== */
PRINT '=== A. Cloud IncomeExpenseHead.PrintCheque ===';

IF COL_LENGTH(N'dbo.IncomeExpenseHead', N'PrintCheque') IS NULL
BEGIN
    ALTER TABLE dbo.IncomeExpenseHead ADD PrintCheque bit NOT NULL
        CONSTRAINT DF_IncomeExpenseHead_PrintCheque DEFAULT (0);
    PRINT 'Added PrintCheque NOT NULL DEFAULT 0';
END
ELSE
BEGIN
    IF EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.IncomeExpenseHead')
          AND name = N'PrintCheque' AND is_nullable = 1
    )
    BEGIN
        UPDATE dbo.IncomeExpenseHead SET PrintCheque = 0 WHERE PrintCheque IS NULL;
        ALTER TABLE dbo.IncomeExpenseHead ALTER COLUMN PrintCheque bit NOT NULL;
        PRINT 'Backfilled NULLs + set NOT NULL';
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.default_constraints dc
        INNER JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
        WHERE dc.parent_object_id = OBJECT_ID(N'dbo.IncomeExpenseHead') AND c.name = N'PrintCheque'
    )
    BEGIN
        ALTER TABLE dbo.IncomeExpenseHead
            ADD CONSTRAINT DF_IncomeExpenseHead_PrintCheque DEFAULT (0) FOR PrintCheque;
        PRINT 'Added DEFAULT (0)';
    END
    ELSE
        PRINT 'PrintCheque already present with DEFAULT';
END

SELECT c.name, t.name AS TypeName, c.is_nullable,
       dc.name AS DefaultConstraint
FROM sys.columns c
INNER JOIN sys.types t ON t.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc
    ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID(N'dbo.IncomeExpenseHead') AND c.name = N'PrintCheque';
GO

/* ========== B) LOCAL ONLY ========== */
PRINT '=== B. Local retry IncomeExpenseHead DeadLetter ===';

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
      AND TableName = N'IncomeExpenseHead';

    PRINT 'IncomeExpenseHead DeadLetter → Pending: ' + CAST(@@ROWCOUNT AS nvarchar(10));

    SELECT Status, COUNT(*) AS Cnt
    FROM dbo.SyncOutbox
    WHERE Direction = N'L2C' AND TableName = N'IncomeExpenseHead'
    GROUP BY Status
    ORDER BY Status;
END
GO
