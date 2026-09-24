-- =============================================================================
-- CustomerMerge.sql
-- Keep Short/ID ချန်ပြီး Merge ID ကို related tables မှာ အစားထိုး + Merge customer Deleted=1
--
-- Rules:
--   1) CustomerOpeningDetail — တူ RefID ၂ ကြောင်း → Amount ပေါင်း၊ merge row ဖျက်
--   2) ReceivableAging — skip
--   3) IncomeExpenseDetail — CashbookTypeID = 3 only
--   4) CustSupTransfer — Debtors(289) / Sales Advance(1490) only
--   5) Merge Customer — Deleted = 1
--
-- USAGE
--   @KeepShort / @MergeShort (သို့) @KeepID / @MergeIDs သတ်မှတ်
--   @DryRun = 1 preview → 0 apply
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* ========== EDIT ========== */
DECLARE @KeepID     int           = 0;
DECLARE @MergeIDs   nvarchar(max) = N'';
DECLARE @KeepShort  nvarchar(50)  = N'fcnlh';
DECLARE @MergeShort nvarchar(max) = N'fsnlh';
DECLARE @DryRun     bit           = 1;   -- 1=preview, 0=apply
DECLARE @MergeBy    nvarchar(100) = SYSTEM_USER;  -- log only
DECLARE @DeletedBy  int           = NULL;         -- Customer.DeletedBy (int UserID), optional
/* ========================== */

DECLARE @Debtors int = 289;
DECLARE @Advance int = 1490;
DECLARE @BatchID uniqueidentifier = NEWID();

-- Short → ID
IF ISNULL(@KeepID, 0) <= 0 AND LEN(ISNULL(@KeepShort, N'')) > 0
BEGIN
    SELECT @KeepID = ID
    FROM dbo.Customer
    WHERE Short = @KeepShort
      AND ISNULL(Deleted, 0) <> 1
      AND ISNULL(IsDeleted, 0) <> 1;

    IF @KeepID IS NULL
    BEGIN
        RAISERROR(N'Keep Short not found: %s', 16, 1, @KeepShort);
        RETURN;
    END
END;

IF LEN(ISNULL(@MergeIDs, N'')) = 0 AND LEN(ISNULL(@MergeShort, N'')) > 0
BEGIN
    SELECT @MergeIDs = STUFF((
        SELECT N',' + CAST(ID AS nvarchar(20))
        FROM dbo.Customer
        WHERE Short IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@MergeShort, N','))
          AND ISNULL(Deleted, 0) <> 1
          AND ISNULL(IsDeleted, 0) <> 1
        FOR XML PATH(N''), TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 1, N'');

    IF LEN(ISNULL(@MergeIDs, N'')) = 0
    BEGIN
        RAISERROR(N'Merge Short not found: %s', 16, 1, @MergeShort);
        RETURN;
    END
END;

IF ISNULL(@KeepID, 0) <= 0 OR LEN(ISNULL(@MergeIDs, N'')) = 0
BEGIN
    RAISERROR(N'Set Keep/Merge Short or ID.', 16, 1);
    RETURN;
END;

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
    RAISERROR(N'KeepID missing/deleted.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM #Merge)
BEGIN
    RAISERROR(N'No merge IDs to process.', 16, 1);
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

SELECT Resolved = N'OK', KeepID = @KeepID, KeepShort = @KeepShort,
       MergeIDs = @MergeIDs, MergeShort = @MergeShort, DryRun = @DryRun, BatchID = @BatchID;

SELECT Step = N'Keep', C.ID, C.Short, C.Name, C.Deleted
FROM dbo.Customer C WHERE C.ID = @KeepID;

SELECT Step = N'MergeFrom', C.ID, C.Short, C.Name, C.Deleted
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
UNION ALL SELECT N'IncomeExpenseDetail (Type=3)', COUNT(*)
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

-- Opening conflict preview
SELECT Conflict = N'Opening same RefID (will collapse)',
       D.RefID, MergeID = D.CustomerID, MergeAmt = D.Amount,
       KeepAmt = K.Amount
FROM dbo.CustomerOpeningDetail D
JOIN #Merge M ON D.CustomerID = M.FromID
JOIN dbo.CustomerOpeningDetail K
  ON K.RefID = D.RefID AND K.CustomerID = @KeepID;

IF @DryRun = 1
BEGIN
    SELECT Msg = N'DryRun=1 — no changes. Set @DryRun=0 to apply.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRAN;

    -- Sale*
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

    -- Opening: collapse then retarget
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

    -- IE Customer only
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

    -- Transfer Debtors / Sales Advance only
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

    -- Merge customer Deleted = 1
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

    SELECT Msg = N'Merge applied.', BatchID = @BatchID, KeepID = @KeepID;
    SELECT TableName, ActionName, Cnt = COUNT(*)
    FROM dbo.CustomerMergeLog
    WHERE BatchID = @BatchID
    GROUP BY TableName, ActionName
    ORDER BY 1, 2;

    SELECT ID, Short, Name, Deleted, IsDeleted
    FROM dbo.Customer
    WHERE ID = @KeepID OR ID IN (SELECT FromID FROM #Merge);

    SELECT LiveAdv = dbo.GetCustomerAdvance(@KeepID),
           LiveBal = dbo.GetCustomerBalance(@KeepID);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @err nvarchar(4000) = ERROR_MESSAGE();
    RAISERROR(N'CustomerMerge failed: %s', 16, 1, @err);
END CATCH;
GO
