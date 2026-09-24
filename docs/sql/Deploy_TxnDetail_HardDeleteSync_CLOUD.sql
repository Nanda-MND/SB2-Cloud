/*
  ============================================================================
  CLOUD ONLY — ALL transaction *Detail hard-delete sync (C2L capture + L2C apply)
  ============================================================================
  Ensures:
    1) Cloud physical DELETE → C2L Op=D (CaptureCloud=1)
    2) SyncApply_*Detail +@Operation so L2C Op=D hard-DELETEs on Cloud
    3) Ghost IsDeleted=1 cleanup + C2L Op=D requeue

  Prerequisite on THIS DB:
    docs/sql/DataSync_10_SyncApply_Generic.sql   (marker: hardDeleteDetail)
    docs/sql/DataSync_28_EnableC2L_Capture.sql   (SyncInstall_CloudCapture) — if missing

  Run AFTER Local:
    docs/sql/Deploy_TxnDetail_HardDeleteSync_LOCAL.sql

  Then rebuild SyncAgent.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'Txn Detail hard-delete sync — CLOUD';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME;
PRINT N'============================================================';

BEGIN TRY EXEC sp_set_session_context @key = N'TxnDetailHdDeployOK', @value = 0; END TRY BEGIN CATCH END CATCH;

IF DB_NAME() IN (N'SB1', N'SB')
BEGIN
    RAISERROR(N'STOP: LOCAL DB. Use Deploy_TxnDetail_HardDeleteSync_LOCAL.sql', 16, 1);
    RETURN;
END

IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
   OR OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) NOT LIKE N'%hardDeleteDetail%'
BEGIN
    RAISERROR(N'STOP: Run DataSync_10_SyncApply_Generic.sql on CLOUD first (need hardDeleteDetail).', 16, 1);
    RETURN;
END

BEGIN TRY EXEC sp_set_session_context @key = N'TxnDetailHdDeployOK', @value = 1; END TRY BEGIN CATCH END CATCH;
PRINT N'OK: SyncApply_Generic has hardDeleteDetail';
GO

IF ISNULL(CONVERT(int, SESSION_CONTEXT(N'TxnDetailHdDeployOK')), 0) <> 1
BEGIN
    PRINT N'SKIP remaining CLOUD steps (prerequisite / wrong DB).';
    SET NOEXEC ON;
END
GO

/* ---- Inventory ---- */
IF OBJECT_ID(N'tempdb..#TxnDetail') IS NOT NULL DROP TABLE #TxnDetail;
CREATE TABLE #TxnDetail (
    TableName    sysname PRIMARY KEY,
    HasIsDeleted bit NOT NULL,
    Source       nvarchar(20) NOT NULL
);

DECLARE @Known TABLE (TableName sysname PRIMARY KEY);
INSERT INTO @Known (TableName) VALUES
    (N'SaleDetail'), (N'PurchaseDetail'),
    (N'SaleOrderDetail'), (N'SaleReturnDetail'),
    (N'PurchaseOrderDetail'), (N'PurchaseReturnDetail'),
    (N'TransferDetail'), (N'AdjustmentDetail'),
    (N'StockReceiveDetail'), (N'ReturnReceiveDetail'), (N'StockOpeningDetail'),
    (N'RawIssueDetail'), (N'FinishGoodsDetail'),
    (N'ReturnStockDetail'), (N'GetStockDetail'),
    (N'IncomeExpenseDetail'), (N'JournalDetail'),
    (N'AccountOpeningDetail'),
    (N'CustomerOpeningDetail'), (N'SupplierOpeningDetail'), (N'ManufacturerOpeningDetail'),
    (N'StockDetail');

INSERT INTO #TxnDetail (TableName, HasIsDeleted, Source)
SELECT t.name,
       CASE WHEN COL_LENGTH(N'dbo.' + t.name, N'IsDeleted') IS NOT NULL THEN 1 ELSE 0 END,
       N'Known'
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'dbo'
INNER JOIN @Known k ON k.TableName = t.name
WHERE COL_LENGTH(N'dbo.' + t.name, N'ID') IS NOT NULL;

INSERT INTO #TxnDetail (TableName, HasIsDeleted, Source)
SELECT t.name,
       CASE WHEN COL_LENGTH(N'dbo.' + t.name, N'IsDeleted') IS NOT NULL THEN 1 ELSE 0 END,
       N'Discovered'
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'dbo'
WHERE t.name LIKE N'%Detail'
  AND t.name NOT LIKE N'Sync%'
  AND t.name NOT LIKE N'%History%'
  AND t.name NOT LIKE N'%Balance%'
  AND COL_LENGTH(N'dbo.' + t.name, N'ID') IS NOT NULL
  AND COL_LENGTH(N'dbo.' + t.name, N'RefID') IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM #TxnDetail d WHERE d.TableName = t.name);

DECLARE @detailCnt int;
SELECT @detailCnt = COUNT(*) FROM #TxnDetail;
PRINT N'Detail tables: ' + CAST(@detailCnt AS nvarchar(20));
SELECT TableName, HasIsDeleted, Source FROM #TxnDetail ORDER BY TableName;
GO

/* ---- SyncConfig: Cloud capture ---- */
PRINT N'--- SyncConfig CaptureCloud=1 / CaptureLocal=0 ---';
IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
    PRINT N'WARN: SyncConfig missing';
ELSE IF COL_LENGTH(N'dbo.SyncConfig', N'CaptureLocal') IS NULL
      OR COL_LENGTH(N'dbo.SyncConfig', N'CaptureCloud') IS NULL
    PRINT N'WARN: SyncConfig CaptureLocal/CaptureCloud columns missing';
ELSE
BEGIN
    DECLARE @t sysname, @sql nvarchar(max);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM #TxnDetail;
    OPEN cur;
    FETCH NEXT FROM cur INTO @t;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = @t)
            SET @sql = N'UPDATE dbo.SyncConfig
SET IsEnabled=1, CaptureLocal=0, CaptureCloud=1
WHERE TableName=@n';
        ELSE
            SET @sql = N'INSERT dbo.SyncConfig
(TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
VALUES(@n, 1, 0, 1, N''ID'', 100, 45, N''TxnDetail C2L hard-delete'')';
        BEGIN TRY
            EXEC sp_executesql @sql, N'@n sysname', @n = @t;
            PRINT N'  Config OK ' + @t;
        END TRY
        BEGIN CATCH
            PRINT N'  Config SKIP ' + @t + N': ' + ERROR_MESSAGE();
        END CATCH
        FETCH NEXT FROM cur INTO @t;
    END
    CLOSE cur; DEALLOCATE cur;
END
GO

/* ---- SyncInstall_CloudCapture (DELETE → C2L Op=D) ---- */
PRINT N'--- SyncInstall_CloudCapture (DELETE → C2L Op=D) ---';
IF OBJECT_ID(N'dbo.SyncInstall_CloudCapture', N'P') IS NULL
    PRINT N'WARN: SyncInstall_CloudCapture missing — run DataSync_28_EnableC2L_Capture.sql then re-run.';
ELSE
BEGIN
    DECLARE @t sysname;
    DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM #TxnDetail;
    OPEN cur2;
    FETCH NEXT FROM cur2 INTO @t;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.SyncInstall_CloudCapture @TableName = @t;
            PRINT N'  Install OK ' + @t;
        END TRY
        BEGIN CATCH
            PRINT N'  Install WARN ' + @t + N': ' + ERROR_MESSAGE();
        END CATCH
        FETCH NEXT FROM cur2 INTO @t;
    END
    CLOSE cur2; DEALLOCATE cur2;
END
GO

/* Re-assert Cloud capture */
PRINT N'--- Re-assert CaptureCloud=1 / CaptureLocal=0 ---';
IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.SyncConfig', N'CaptureLocal') IS NOT NULL
   AND COL_LENGTH(N'dbo.SyncConfig', N'CaptureCloud') IS NOT NULL
BEGIN
    UPDATE c
    SET IsEnabled = 1, CaptureLocal = 0, CaptureCloud = 1
    FROM dbo.SyncConfig c
    INNER JOIN #TxnDetail d ON d.TableName = c.TableName;
    PRINT N'Re-asserted: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END
GO

/* ---- SyncApply_*Detail (+@Operation) for L2C deletes landing here ---- */
PRINT N'--- SyncApply_*Detail wrappers ---';
DECLARE @t sysname, @p sysname, @sql nvarchar(max), @drop nvarchar(max);
DECLARE cur4 CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM #TxnDetail;
OPEN cur4;
FETCH NEXT FROM cur4 INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @p = N'SyncApply_' + @t;

    IF OBJECT_ID(N'dbo.' + @p, N'P') IS NOT NULL
    BEGIN
        SET @drop = N'DROP PROCEDURE dbo.' + QUOTENAME(@p);
        EXEC(@drop);
    END

    SET @sql = N'
CREATE PROCEDURE dbo.' + QUOTENAME(@p) + N'
    @Source varchar(10),
    @PayloadJson nvarchar(max),
    @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500),
    @OutboxID bigint = NULL,
    @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT,
    @Applied bit OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N''' + REPLACE(@t, '''', '''''') + N''',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END';
    BEGIN TRY
        EXEC(@sql);
        PRINT N'  ' + @p + N' OK';
    END TRY
    BEGIN CATCH
        PRINT N'  ' + @p + N' FAIL: ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM cur4 INTO @t;
END
CLOSE cur4;
DEALLOCATE cur4;
GO

/* ---- Ghost cleanup ---- */
PRINT N'--- Hard-delete IsDeleted=1 ghosts ---';
DECLARE @t sysname, @sql nvarchar(max), @n int;
DECLARE cur5 CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName FROM #TxnDetail WHERE HasIsDeleted = 1;
OPEN cur5;
FETCH NEXT FROM cur5 INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
        BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = 1; END TRY BEGIN CATCH END CATCH;
        SET @sql = N'DELETE FROM dbo.' + QUOTENAME(@t) + N' WHERE ISNULL(IsDeleted,0)=1';
        EXEC(@sql);
        SET @n = @@ROWCOUNT;
        PRINT N'  ' + @t + N': ' + CAST(@n AS nvarchar(20));
        BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
        BEGIN TRY EXEC sp_set_session_context @key = N'SyncAllowPhysicalDelete', @value = NULL; END TRY BEGIN CATCH END CATCH;
    END TRY
    BEGIN CATCH
        PRINT N'  ' + @t + N' SKIP: ' + ERROR_MESSAGE();
    END CATCH
    FETCH NEXT FROM cur5 INTO @t;
END
CLOSE cur5; DEALLOCATE cur5;
GO

/* ---- Requeue C2L Op=D (7d) ---- */
PRINT N'--- Requeue C2L *Detail Op=D (7d) ---';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NULL
    PRINT N'No SyncOutbox — skip requeue.';
ELSE
BEGIN
    BEGIN TRY
        UPDATE dbo.SyncOutbox
        SET Status = N'Pending', AttemptCount = 0, LastError = NULL,
            SyncedAt = NULL, SyncModifiedAt = SYSUTCDATETIME()
        WHERE Direction = N'C2L'
          AND TableName LIKE N'%Detail'
          AND Operation = N'D'
          AND Status IN (N'Synced', N'Conflict', N'DeadLetter', N'Syncing')
          AND CreatedAt >= DATEADD(day, -7, SYSUTCDATETIME());
        PRINT N'Requeued: ' + CAST(@@ROWCOUNT AS nvarchar(20));
    END TRY
    BEGIN CATCH
        PRINT N'Requeue SKIP: ' + ERROR_MESSAGE();
    END CATCH
END
GO

/* ---- VERIFY (materialize — no aggregate+subquery / Msg 130) ---- */
PRINT N'--- VERIFY (TriggerOK + ApplyOK + CaptureOK must be OK) ---';
IF OBJECT_ID(N'tempdb..#Verify') IS NOT NULL DROP TABLE #Verify;
CREATE TABLE #Verify (
    TableName  sysname NOT NULL PRIMARY KEY,
    Source     nvarchar(20) NOT NULL,
    CaptureOK  nvarchar(20) NOT NULL,
    TriggerOK  nvarchar(20) NOT NULL,
    ApplyOK    nvarchar(20) NOT NULL
);

DECLARE @t sysname, @src nvarchar(20);
DECLARE @cap nvarchar(20), @trg nvarchar(20), @app nvarchar(20);
DECLARE @oid int;

DECLARE vcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, Source FROM #TxnDetail ORDER BY TableName;
OPEN vcur;
FETCH NEXT FROM vcur INTO @t, @src;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cap = N'BAD';
    IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
        SET @cap = N'NOCFG';
    ELSE IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig c WHERE c.TableName = @t)
        SET @cap = N'MISSING';
    ELSE IF EXISTS (
        SELECT 1 FROM dbo.SyncConfig c
        WHERE c.TableName = @t
          AND c.IsEnabled = 1 AND c.CaptureCloud = 1 AND ISNULL(c.CaptureLocal, 0) = 0
    )
        SET @cap = N'OK';

    SET @trg = N'BAD';
    IF EXISTS (
        SELECT 1 FROM sys.triggers tr
        WHERE OBJECT_NAME(tr.parent_id) = @t
          AND tr.name LIKE N'tr_SyncOutbox_%'
          AND OBJECT_DEFINITION(tr.object_id) LIKE N'%DELETE%'
          AND OBJECT_DEFINITION(tr.object_id) LIKE N'%''D''%'
    )
        SET @trg = N'OK';

    SET @app = N'BAD';
    SET @oid = OBJECT_ID(N'dbo.SyncApply_' + @t, N'P');
    IF @oid IS NOT NULL AND OBJECT_DEFINITION(@oid) LIKE N'%@Operation%'
        SET @app = N'OK';

    INSERT INTO #Verify (TableName, Source, CaptureOK, TriggerOK, ApplyOK)
    VALUES (@t, @src, @cap, @trg, @app);

    FETCH NEXT FROM vcur INTO @t, @src;
END
CLOSE vcur; DEALLOCATE vcur;

SELECT * FROM #Verify ORDER BY TableName;

DECLARE @bad int;
SELECT @bad = COUNT(*) FROM #Verify
WHERE CaptureOK <> N'OK' OR TriggerOK <> N'OK' OR ApplyOK <> N'OK';
PRINT N'BadCount: ' + CAST(ISNULL(@bad, 0) AS nvarchar(20));
GO

PRINT N'============================================================';
PRINT N'CLOUD DONE → rebuild SyncAgent';
PRINT N'TEST both directions: delete detail on Local and on Cloud.';
PRINT N'Optional orphans: Cleanup_DetailDeleteGhosts_2Days_*.sql';
PRINT N'============================================================';
GO

SET NOEXEC OFF;
GO
