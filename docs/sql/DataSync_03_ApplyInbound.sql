/*
  Data Sync — Apply inbound change (Local-wins conflict rules)
  Install on BOTH Local and Cloud databases.

  Called by Sync Agent:
    - On Cloud when pushing Local changes (@Source = 'Local')
    - On Local when pulling Cloud changes (@Source = 'Cloud')
*/

SET NOCOUNT ON;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.SyncApplyInbound', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApplyInbound;
GO

CREATE PROCEDURE dbo.SyncApplyInbound
    @Source             varchar(10),   -- 'Local' | 'Cloud'
    @TableName          sysname,
    @PrimaryKeyJson     nvarchar(500),
    @Operation          char(1),       -- I/U/D
    @PayloadJson        nvarchar(max),
    @RemoteModifiedAt   datetime2(3),
    @OutboxID           bigint = NULL,
    @ConflictLogged     bit OUTPUT,
    @Applied            bit OUTPUT
AS
BEGIN
    SET XACT_ABORT ON;
    SET @ConflictLogged = 0;
    SET @Applied = 0;

    DECLARE @Direction char(3) = CASE WHEN @Source = 'Local' THEN 'L2C' ELSE 'C2L' END;

    -- Cloud → Local: local always wins if local row is newer or has pending local outbox
    IF @Source = 'Cloud'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.SyncOutbox o WITH (NOLOCK)
            WHERE o.Direction = 'L2C'
              AND o.TableName = @TableName
              AND o.PrimaryKeyJson = @PrimaryKeyJson
              AND o.Status IN ('Pending', 'Syncing')
        )
        BEGIN
            INSERT INTO dbo.SyncConflictLog (
                Direction, TableName, PrimaryKeyJson, Resolution,
                RemotePayloadJson, RemoteModifiedAt, Message)
            VALUES (
                'C2L', @TableName, @PrimaryKeyJson, 'LocalWinsSkipped',
                @PayloadJson, @RemoteModifiedAt,
                N'Local outbox has pending changes for this key; cloud update skipped.');

            SET @ConflictLogged = 1;
            RETURN;
        END

        -- Table-specific modified-at check requires dynamic SQL; agent passes pre-check or use generic stub:
        -- For pilot: log and skip if SyncModifiedAt on target would lose to local (implemented per-table in agent)
    END

    -- Local → Cloud: always apply (local is source of truth)
    -- Log if cloud had different version (optional compare in agent before call)

    BEGIN TRY
        -- Dynamic MERGE is table-specific; Sync Agent should call table-specific wrappers
        -- e.g. SyncApply_Customer, SyncApply_SaleHead generated from metadata.
        -- This stub marks intent; replace with generated code or use SQL Server sync tool.

        IF @Operation = 'D'
        BEGIN
            -- Soft delete apply pattern (when IsDeleted columns exist):
            -- UPDATE target SET IsDeleted=1, DeletedAt=@RemoteModifiedAt, Deleted=1 WHERE PK match
            SET @Applied = 0; -- set 1 when table wrapper executes
        END
        ELSE
        BEGIN
            SET @Applied = 0; -- set 1 when MERGE wrapper executes
        END

        IF @Source = 'Local' AND @Applied = 0
        BEGIN
            -- Wrapper not yet generated for this table
            RAISERROR(N'SyncApplyInbound: no wrapper for table %s. Generate SyncApply_%s procedure.', 16, 1, @TableName, @TableName);
        END
    END TRY
    BEGIN CATCH
        DECLARE @Err nvarchar(max) = ERROR_MESSAGE();
        IF @OutboxID IS NOT NULL
        BEGIN
            UPDATE dbo.SyncOutbox
            SET AttemptCount = AttemptCount + 1,
                LastError = @Err,
                Status = CASE WHEN AttemptCount + 1 >= 10 THEN 'DeadLetter' ELSE 'Pending' END
            WHERE OutboxID = @OutboxID;

            IF (SELECT AttemptCount FROM dbo.SyncOutbox WHERE OutboxID = @OutboxID) >= 10
            BEGIN
                INSERT INTO dbo.SyncDeadLetter (OutboxID, TableName, PrimaryKeyJson, PayloadJson, LastError)
                SELECT OutboxID, TableName, PrimaryKeyJson, PayloadJson, @Err
                FROM dbo.SyncOutbox WHERE OutboxID = @OutboxID;
            END
        END;
        THROW;
    END CATCH
END
GO

-- ============================================================
-- Customer apply — delegate to SyncApply_Generic (same pattern as Sales/Purchase)
-- Requires: DataSync_10_SyncApply_Generic.sql
-- ============================================================
IF OBJECT_ID('dbo.SyncApply_Customer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncApply_Customer;
GO

CREATE PROCEDURE dbo.SyncApply_Customer
    @Source             varchar(10),
    @PayloadJson        nvarchar(max),
    @RemoteModifiedAt   datetime2(3),
    @PrimaryKeyJson     nvarchar(500),
    @OutboxID           bigint = NULL,
    @ConflictLogged     bit OUTPUT,
    @Applied            bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'Customer',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = NULL,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

-- ============================================================
-- Agent helpers: claim batch / complete batch
-- ============================================================
IF OBJECT_ID('dbo.SyncClaimOutboxBatch', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncClaimOutboxBatch;
GO

CREATE PROCEDURE dbo.SyncClaimOutboxBatch
    @Direction  char(3),
    @BatchSize  int = 100
AS
BEGIN
    SET NOCOUNT ON;

    -- Recover rows stuck in Syncing after agent crash
    UPDATE dbo.SyncOutbox
    SET Status = 'Pending'
    WHERE Direction = @Direction AND Status = 'Syncing'
      AND CreatedAt < DATEADD(minute, -5, sysutcdatetime());

    DECLARE @claimed TABLE (OutboxID bigint PRIMARY KEY);

    ;WITH cte AS (
        SELECT TOP (@BatchSize) o.OutboxID
        FROM dbo.SyncOutbox o WITH (UPDLOCK, READPAST, ROWLOCK)
        LEFT JOIN dbo.SyncConfig c ON c.TableName = o.TableName
        WHERE o.Direction = @Direction AND o.Status = 'Pending'
        ORDER BY COALESCE(c.Priority, 100), o.CreatedAt
    )
    UPDATE o SET Status = 'Syncing', AttemptCount = AttemptCount + 1
    OUTPUT inserted.OutboxID INTO @claimed(OutboxID)
    FROM dbo.SyncOutbox o
    INNER JOIN cte ON cte.OutboxID = o.OutboxID;

    SELECT o.OutboxID, o.TableName, o.PrimaryKeyJson, o.Operation, o.PayloadJson, o.SyncModifiedAt
    FROM dbo.SyncOutbox o
    INNER JOIN @claimed c ON c.OutboxID = o.OutboxID
    LEFT JOIN dbo.SyncConfig cfg ON cfg.TableName = o.TableName
    ORDER BY COALESCE(cfg.Priority, 100), o.CreatedAt;
END
GO

IF OBJECT_ID('dbo.SyncCompleteOutbox', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SyncCompleteOutbox;
GO

CREATE PROCEDURE dbo.SyncCompleteOutbox
    @OutboxID   bigint,
    @Status     varchar(20)  -- Synced | Conflict
AS
BEGIN
    UPDATE dbo.SyncOutbox
    SET Status = @Status, SyncedAt = sysutcdatetime(), LastError = NULL
    WHERE OutboxID = @OutboxID;
END
GO

PRINT 'DataSync_03_ApplyInbound.sql completed.';
GO
