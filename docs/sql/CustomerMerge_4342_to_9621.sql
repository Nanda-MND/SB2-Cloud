/*
  Merge Customer 4342 (bnw - Business World)
       → Keep 9621 (bsnwc - Business World Co.,Ltd)
  Soft-delete 4342 after retargeting all related transactions.

  Based on: docs/sql/CustomerMerge.sql

  Steps:
  1) Run with @DryRun = 1  → preview counts / opening conflicts
  2) Run with @DryRun = 0  → apply merge + soft delete
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* ========== EDIT ========== */
DECLARE @KeepID     int           = 9621;   -- keep
DECLARE @MergeIDs   nvarchar(max) = N'4342'; -- soft-delete after merge
DECLARE @KeepShort  nvarchar(50)  = N'';
DECLARE @MergeShort nvarchar(max) = N'';
DECLARE @DryRun     bit           = 1;      -- 1=preview, 0=apply
DECLARE @MergeBy    nvarchar(100) = SYSTEM_USER;
DECLARE @DeletedBy  int           = NULL;   -- optional UserID for Customer.DeletedBy
/* ========================== */

DECLARE @Debtors int = 289;
DECLARE @Advance int = 1490;
DECLARE @BatchID uniqueidentifier = NEWID();

IF OBJECT_ID(N'tempdb..#Merge') IS NOT NULL DROP TABLE #Merge;
IF OBJECT_ID(N'tempdb..#OpenCollapse') IS NOT NULL DROP TABLE #OpenCollapse;

CREATE TABLE #Merge (FromID int PRIMARY KEY);

DECLARE @sql nvarchar(max) =
    N'INSERT INTO #Merge(FromID)
      SELECT DISTINCT ID FROM dbo.Customer
      WHERE ID IN (' + @MergeIDs + N') AND ID <> ' + CAST(@KeepID AS nvarchar(20));
EXEC (@sql);

IF NOT EXISTS (
    SELECT 1 FROM dbo.Customer
    WHERE ID = @KeepID AND ISNULL(Deleted, 0) <> 1 AND ISNULL(IsDeleted, 0) <> 1
)
BEGIN
    RAISERROR(N'KeepID 9621 missing/deleted.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM #Merge)
BEGIN
    RAISERROR(N'Merge ID 4342 not found (or already same as Keep).', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'dbo.CustomerMergeLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerMergeLog
    (
        LogID      bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
        BatchID    uniqueidentifier NOT NULL,
        MergedAt   datetime NOT NULL CONSTRAINT DF_CustomerMergeLog_MergedAt DEFAULT (GETDATE()),
        MergedBy   nvarchar(100) NULL,
        KeepID     int NOT NULL,
        FromID     int NOT NULL,
        TableName  sysname NOT NULL,
        RowID      int NULL,
        ActionName nvarchar(40) NOT NULL,
        Note       nvarchar(400) NULL
    );
END;

SELECT Resolved = N'OK', KeepID = @KeepID, MergeIDs = @MergeIDs, DryRun = @DryRun, BatchID = @BatchID;

SELECT Step = N'Keep', C.ID, C.Short, C.Name, C.Deleted, C.IsDeleted
FROM dbo.Customer C WHERE C.ID = @KeepID;

SELECT Step = N'MergeFrom', C.ID, C.Short, C.Name, C.Deleted, C.IsDeleted
FROM dbo.Customer C
JOIN #Merge M ON M.FromID = C.ID;

SELECT TableName = N'SaleHead', Cnt = COUNT(*)
FROM dbo.SaleHead H JOIN #Merge M ON H.CustomerID = M.FromID WHERE ISNULL(H.Deleted, 0) <> 1
UNION ALL SELECT N'SaleOrderHead', COUNT(*)
FROM dbo.SaleOrderHead H JOIN #Merge M ON H.CustomerID = M.FromID WHERE ISNULL(H.Deleted, 0) <> 1
UNION ALL SELECT N'SaleReturnHead', COUNT(*)
FROM dbo.SaleReturnHead H JOIN #Merge M ON H.CustomerID = M.FromID WHERE ISNULL(H.Deleted, 0) <> 1
UNION ALL SELECT N'CustomerOpeningDetail', COUNT(*)
FROM dbo.CustomerOpeningDetail D JOIN #Merge M ON D.CustomerID = M.FromID
UNION ALL SELECT N'IncomeExpenseDetail (CashbookType=3)', COUNT(*)
FROM dbo.IncomeExpenseDetail D
JOIN dbo.IncomeExpenseHead H ON H.ID = D.RefID
JOIN #Merge M ON D.SourceID = M.FromID
WHERE ISNULL(H.Deleted, 0) <> 1 AND H.CashbookTypeID = 3
UNION ALL SELECT N'CustSupTransfer From (289/1490)', COUNT(*)
FROM dbo.CustSupTransfer H JOIN #Merge M ON H.FromSourceID = M.FromID
WHERE ISNULL(H.Deleted, 0) <> 1 AND H.FromAcctID IN (@Debtors, @Advance)
UNION ALL SELECT N'CustSupTransfer To (289/1490)', COUNT(*)
FROM dbo.CustSupTransfer H JOIN #Merge M ON H.ToSourceID = M.FromID
WHERE ISNULL(H.Deleted, 0) <> 1 AND H.ToAcctID IN (@Debtors, @Advance)
ORDER BY TableName;

SELECT Conflict = N'Opening same RefID (will collapse Amount into Keep)',
       D.RefID, MergeID = D.CustomerID, MergeAmt = D.Amount, KeepAmt = K.Amount
FROM dbo.CustomerOpeningDetail D
JOIN #Merge M ON D.CustomerID = M.FromID
JOIN dbo.CustomerOpeningDetail K
  ON K.RefID = D.RefID AND K.CustomerID = @KeepID;

IF @DryRun = 1
BEGIN
    SELECT Msg = N'DryRun=1 — no changes. Set @DryRun=0 and re-run to apply.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRAN;

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, H.CustomerID, N'SaleHead', H.ID, N'UPDATE', H.AutoID
    FROM dbo.SaleHead H JOIN #Merge M ON H.CustomerID = M.FromID;

    UPDATE H SET CustomerID = @KeepID
    FROM dbo.SaleHead H JOIN #Merge M ON H.CustomerID = M.FromID;

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, H.CustomerID, N'SaleOrderHead', H.ID, N'UPDATE', H.AutoID
    FROM dbo.SaleOrderHead H JOIN #Merge M ON H.CustomerID = M.FromID;

    UPDATE H SET CustomerID = @KeepID
    FROM dbo.SaleOrderHead H JOIN #Merge M ON H.CustomerID = M.FromID;

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, H.CustomerID, N'SaleReturnHead', H.ID, N'UPDATE', H.AutoID
    FROM dbo.SaleReturnHead H JOIN #Merge M ON H.CustomerID = M.FromID;

    UPDATE H SET CustomerID = @KeepID
    FROM dbo.SaleReturnHead H JOIN #Merge M ON H.CustomerID = M.FromID;

    ;WITH Dup AS
    (
        SELECT
            MergeRowID = D.ID,
            FromID = D.CustomerID,
            MergeAmount = D.Amount,
            KeepRowID = K.ID
        FROM dbo.CustomerOpeningDetail D
        JOIN #Merge M ON D.CustomerID = M.FromID
        JOIN dbo.CustomerOpeningDetail K
          ON K.RefID = D.RefID AND K.CustomerID = @KeepID
    )
    SELECT * INTO #OpenCollapse FROM Dup;

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, FromID, N'CustomerOpeningDetail', MergeRowID, N'DELETE',
           N'Amount+ into KeepRow ' + CAST(KeepRowID AS nvarchar(20))
    FROM #OpenCollapse;

    UPDATE K
    SET Amount = ISNULL(K.Amount, 0) + ISNULL(C.MergeAmount, 0)
    FROM dbo.CustomerOpeningDetail K
    JOIN #OpenCollapse C ON C.KeepRowID = K.ID;

    DELETE D
    FROM dbo.CustomerOpeningDetail D
    JOIN #OpenCollapse C ON C.MergeRowID = D.ID;

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, D.CustomerID, N'CustomerOpeningDetail', D.ID, N'UPDATE', NULL
    FROM dbo.CustomerOpeningDetail D
    JOIN #Merge M ON D.CustomerID = M.FromID;

    UPDATE D SET CustomerID = @KeepID
    FROM dbo.CustomerOpeningDetail D
    JOIN #Merge M ON D.CustomerID = M.FromID;

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, D.SourceID, N'IncomeExpenseDetail', D.ID, N'UPDATE', H.AutoID
    FROM dbo.IncomeExpenseDetail D
    JOIN dbo.IncomeExpenseHead H ON H.ID = D.RefID
    JOIN #Merge M ON D.SourceID = M.FromID
    WHERE H.CashbookTypeID = 3;

    UPDATE D SET SourceID = @KeepID
    FROM dbo.IncomeExpenseDetail D
    JOIN dbo.IncomeExpenseHead H ON H.ID = D.RefID
    JOIN #Merge M ON D.SourceID = M.FromID
    WHERE H.CashbookTypeID = 3;

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, H.FromSourceID, N'CustSupTransfer', H.ID, N'UPDATE', N'From'
    FROM dbo.CustSupTransfer H
    JOIN #Merge M ON H.FromSourceID = M.FromID
    WHERE H.FromAcctID IN (@Debtors, @Advance);

    UPDATE H SET FromSourceID = @KeepID
    FROM dbo.CustSupTransfer H
    JOIN #Merge M ON H.FromSourceID = M.FromID
    WHERE H.FromAcctID IN (@Debtors, @Advance);

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, H.ToSourceID, N'CustSupTransfer', H.ID, N'UPDATE', N'To'
    FROM dbo.CustSupTransfer H
    JOIN #Merge M ON H.ToSourceID = M.FromID
    WHERE H.ToAcctID IN (@Debtors, @Advance);

    UPDATE H SET ToSourceID = @KeepID
    FROM dbo.CustSupTransfer H
    JOIN #Merge M ON H.ToSourceID = M.FromID
    WHERE H.ToAcctID IN (@Debtors, @Advance);

    INSERT INTO dbo.CustomerMergeLog (BatchID, MergedBy, KeepID, FromID, TableName, RowID, ActionName, Note)
    SELECT @BatchID, @MergeBy, @KeepID, C.ID, N'Customer', C.ID, N'SOFTDELETE', C.Short
    FROM dbo.Customer C
    JOIN #Merge M ON C.ID = M.FromID;

    UPDATE C
    SET Deleted = 1,
        IsDeleted = 1,
        InActive = 1,
        DeletedAt = GETDATE(),
        DeletedBy = @DeletedBy
    FROM dbo.Customer C
    JOIN #Merge M ON C.ID = M.FromID;

    COMMIT TRAN;

    SELECT Msg = N'Merge applied.', BatchID = @BatchID, KeepID = @KeepID, SoftDeleted = 4342;

    SELECT TableName, ActionName, Cnt = COUNT(*)
    FROM dbo.CustomerMergeLog
    WHERE BatchID = @BatchID
    GROUP BY TableName, ActionName
    ORDER BY 1, 2;

    SELECT ID, Short, Name, Deleted, IsDeleted, InActive, DeletedAt
    FROM dbo.Customer
    WHERE ID IN (9621, 4342);

    SELECT LiveAdv = dbo.GetCustomerAdvance(9621),
           LiveBal = dbo.GetCustomerBalance(9621);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @err nvarchar(4000) = ERROR_MESSAGE();
    RAISERROR(N'CustomerMerge failed: %s', 16, 1, @err);
END CATCH;
GO
