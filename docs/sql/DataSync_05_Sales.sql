/*
  Data Sync - Sales (SaleHead + SaleDetail)
  Run on BOTH Local and Cloud databases (same order as Customer rollout).

  Prerequisites: DataSync_01, DataSync_03 already applied.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ============================================================
-- Sync columns: SaleHead
-- ============================================================
IF COL_LENGTH('dbo.SaleHead', 'IsDeleted') IS NULL
    ALTER TABLE dbo.SaleHead ADD IsDeleted bit NOT NULL CONSTRAINT DF_SaleHead_IsDeleted DEFAULT (0);
GO
IF COL_LENGTH('dbo.SaleHead', 'DeletedAt') IS NULL
    ALTER TABLE dbo.SaleHead ADD DeletedAt datetime2(3) NULL;
GO
IF COL_LENGTH('dbo.SaleHead', 'DeletedBy') IS NULL
    ALTER TABLE dbo.SaleHead ADD DeletedBy int NULL;
GO
IF COL_LENGTH('dbo.SaleHead', 'SyncModifiedAt') IS NULL
    ALTER TABLE dbo.SaleHead ADD SyncModifiedAt datetime2(3) NOT NULL CONSTRAINT DF_SaleHead_SyncMod DEFAULT (sysutcdatetime());
GO
IF COL_LENGTH('dbo.SaleHead', 'SyncModifiedBy') IS NULL
    ALTER TABLE dbo.SaleHead ADD SyncModifiedBy int NULL;
GO
IF COL_LENGTH('dbo.SaleHead', 'SyncOrigin') IS NULL
    ALTER TABLE dbo.SaleHead ADD SyncOrigin tinyint NOT NULL CONSTRAINT DF_SaleHead_SyncOrigin DEFAULT (1);
GO
IF COL_LENGTH('dbo.SaleHead', 'SyncRowVersion') IS NULL
    ALTER TABLE dbo.SaleHead ADD SyncRowVersion rowversion;
GO

EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
UPDATE dbo.SaleHead
SET IsDeleted = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN 1 ELSE 0 END,
    DeletedAt = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN ISNULL(DeletedAt, SyncModifiedAt) ELSE NULL END
WHERE IsDeleted = 0 AND ISNULL(Deleted, 0) <> 0;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
GO

-- ============================================================
-- Sync columns: SaleDetail
-- ============================================================
IF COL_LENGTH('dbo.SaleDetail', 'IsDeleted') IS NULL
    ALTER TABLE dbo.SaleDetail ADD IsDeleted bit NOT NULL CONSTRAINT DF_SaleDetail_IsDeleted DEFAULT (0);
GO
IF COL_LENGTH('dbo.SaleDetail', 'DeletedAt') IS NULL
    ALTER TABLE dbo.SaleDetail ADD DeletedAt datetime2(3) NULL;
GO
IF COL_LENGTH('dbo.SaleDetail', 'DeletedBy') IS NULL
    ALTER TABLE dbo.SaleDetail ADD DeletedBy int NULL;
GO
IF COL_LENGTH('dbo.SaleDetail', 'SyncModifiedAt') IS NULL
    ALTER TABLE dbo.SaleDetail ADD SyncModifiedAt datetime2(3) NOT NULL CONSTRAINT DF_SaleDetail_SyncMod DEFAULT (sysutcdatetime());
GO
IF COL_LENGTH('dbo.SaleDetail', 'SyncModifiedBy') IS NULL
    ALTER TABLE dbo.SaleDetail ADD SyncModifiedBy int NULL;
GO
IF COL_LENGTH('dbo.SaleDetail', 'SyncOrigin') IS NULL
    ALTER TABLE dbo.SaleDetail ADD SyncOrigin tinyint NOT NULL CONSTRAINT DF_SaleDetail_SyncOrigin DEFAULT (1);
GO
IF COL_LENGTH('dbo.SaleDetail', 'SyncRowVersion') IS NULL
    ALTER TABLE dbo.SaleDetail ADD SyncRowVersion rowversion;
GO

-- ============================================================
-- Metadata triggers (no SuppressOutbox)
-- ============================================================
IF OBJECT_ID('dbo.tr_SaleHead_SyncMetadata', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SaleHead_SyncMetadata;
GO
CREATE TRIGGER dbo.tr_SaleHead_SyncMetadata ON dbo.SaleHead AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
        WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1))) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE h SET h.SyncModifiedAt = sysutcdatetime(), h.SyncModifiedBy = COALESCE(i.SyncModifiedBy, h.SyncModifiedBy)
    FROM dbo.SaleHead h INNER JOIN inserted i ON i.ID = h.ID
    LEFT JOIN deleted d ON d.ID = i.ID
    WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1));
END
GO

IF OBJECT_ID('dbo.tr_SaleDetail_SyncMetadata', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SaleDetail_SyncMetadata;
GO
CREATE TRIGGER dbo.tr_SaleDetail_SyncMetadata ON dbo.SaleDetail AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
        WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1))) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE d SET d.SyncModifiedAt = sysutcdatetime(), d.SyncModifiedBy = COALESCE(i.SyncModifiedBy, d.SyncModifiedBy)
    FROM dbo.SaleDetail d INNER JOIN inserted i ON i.ID = d.ID
    LEFT JOIN deleted del ON del.ID = i.ID
    WHERE del.ID IS NULL OR (i.SyncModifiedAt = del.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(del.SyncModifiedBy,-1));
END
GO

IF OBJECT_ID('dbo.tr_SaleHead_SoftDeleteSync', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SaleHead_SoftDeleteSync;
GO
CREATE TRIGGER dbo.tr_SaleHead_SoftDeleteSync ON dbo.SaleHead AFTER UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i INNER JOIN deleted d ON d.ID = i.ID WHERE ISNULL(i.Deleted,0) <> 0 AND ISNULL(d.Deleted,0) = 0) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE h SET h.IsDeleted = 1, h.DeletedAt = COALESCE(h.DeletedAt, sysutcdatetime())
    FROM dbo.SaleHead h INNER JOIN inserted i ON i.ID = h.ID
    WHERE ISNULL(i.Deleted,0) <> 0 AND ISNULL(h.IsDeleted,0) = 0;
END
GO

-- ============================================================
-- Outbox capture triggers
-- ============================================================
IF OBJECT_ID('dbo.tr_SyncOutbox_SaleHead', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncOutbox_SaleHead;
GO
CREATE TRIGGER dbo.tr_SyncOutbox_SaleHead ON dbo.SaleHead AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressOutbox') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'SaleHead' AND IsEnabled = 1 AND CaptureLocal = 1) RETURN;
    ;WITH changed AS (
        SELECT i.ID,
            Operation = CASE WHEN d.ID IS NULL THEN 'I'
                WHEN ISNULL(i.IsDeleted,0) = 1 AND ISNULL(d.IsDeleted,0) = 0 THEN 'D' ELSE 'U' END,
            PayloadJson = (SELECT i.ID, i.Date, i.AutoID, i.DocumentID, i.SaleID, i.LocationID, i.CustomerID,
                i.PaymentID, i.AccountID, i.OrderID, i.AdvBalance, i.AdvAmount, i.Balance, i.Amount, i.Discount,
                i.NetAmount, i.TaxAmount, i.AddAmount, i.TotalAmount, i.PaidAmount, i.TotalBalance, i.Remark,
                i.TransportID, i.GateID, i.CarID, i.UserID, i.EditUserID, i.EditDate, i.QRID, i.Issue,
                Deleted = ISNULL(i.Deleted,0), IsDeleted = ISNULL(i.IsDeleted,0),
                i.SyncModifiedAt, i.SyncModifiedBy, i.SyncOrigin
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            PrimaryKeyJson = (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
        FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT 'L2C', N'SaleHead', c.PrimaryKeyJson, c.Operation, c.PayloadJson, c.SyncModifiedAt FROM changed c
    WHERE NOT EXISTS (SELECT 1 FROM dbo.SyncOutbox o WHERE o.Direction='L2C' AND o.TableName=N'SaleHead'
        AND o.PrimaryKeyJson = c.PrimaryKeyJson AND o.Status='Pending' AND o.CreatedAt > DATEADD(second,-1,sysutcdatetime()));
END
GO

IF OBJECT_ID('dbo.tr_SyncOutbox_SaleDetail', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncOutbox_SaleDetail;
GO
CREATE TRIGGER dbo.tr_SyncOutbox_SaleDetail ON dbo.SaleDetail AFTER INSERT, UPDATE, DELETE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressOutbox') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'SaleDetail' AND IsEnabled = 1 AND CaptureLocal = 1) RETURN;

    ;WITH changed AS (
        SELECT src.ID, src.RefID, src.Operation, src.PayloadJson, src.PrimaryKeyJson, src.SyncModifiedAt FROM (
            SELECT i.ID, i.RefID,
                Operation = CASE WHEN d.ID IS NULL THEN 'I'
                    WHEN ISNULL(i.IsDeleted,0) = 1 AND ISNULL(d.IsDeleted,0) = 0 THEN 'D' ELSE 'U' END,
                PayloadJson = (SELECT i.ID, i.RefID, i.Sr, i.CodeID, i.BrandID, i.UnitID, i.Qty, i.Weight, i.Price,
                    i.TotalWeight, i.Amount, i.Qty1, i.Qty2, i.Remark, i.OrderRefID, i.LocID,
                    IsDeleted = ISNULL(i.IsDeleted,0), i.SyncModifiedAt, i.SyncModifiedBy, i.SyncOrigin
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                PrimaryKeyJson = (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
            FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
            UNION ALL
            SELECT d.ID, d.RefID, Operation = 'D',
                PayloadJson = (SELECT d.ID, d.RefID, d.Sr, d.CodeID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                PrimaryKeyJson = (SELECT d.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                SyncModifiedAt = sysutcdatetime()
            FROM deleted d WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.ID = d.ID)
        ) src
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT 'L2C', N'SaleDetail', c.PrimaryKeyJson, c.Operation, c.PayloadJson, c.SyncModifiedAt FROM changed c
    WHERE NOT EXISTS (SELECT 1 FROM dbo.SyncOutbox o WHERE o.Direction='L2C' AND o.TableName=N'SaleDetail'
        AND o.PrimaryKeyJson = c.PrimaryKeyJson AND o.Status='Pending' AND o.CreatedAt > DATEADD(second,-1,sysutcdatetime()));
END
GO

-- Block physical delete on SaleHead
IF OBJECT_ID('dbo.tr_SyncBlockDelete_SaleHead', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncBlockDelete_SaleHead;
GO
CREATE TRIGGER dbo.tr_SyncBlockDelete_SaleHead ON dbo.SaleHead INSTEAD OF DELETE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncAllowPhysicalDelete') = 1 BEGIN DELETE h FROM dbo.SaleHead h INNER JOIN deleted d ON d.ID = h.ID; RETURN; END
    RAISERROR(N'Physical DELETE blocked on SaleHead. Use soft delete (Deleted=1).', 16, 1);
END
GO

-- ============================================================
-- Apply procedures (delegate to SyncApply_Generic for schema-safe TRY_CAST)
-- Requires: DataSync_10_SyncApply_Generic.sql
-- ============================================================
IF OBJECT_ID('dbo.SyncApply_SaleHead', 'P') IS NOT NULL DROP PROCEDURE dbo.SyncApply_SaleHead;
GO
CREATE PROCEDURE dbo.SyncApply_SaleHead
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL, @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'SaleHead',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

IF OBJECT_ID('dbo.SyncApply_SaleDetail', 'P') IS NOT NULL DROP PROCEDURE dbo.SyncApply_SaleDetail;
GO
CREATE PROCEDURE dbo.SyncApply_SaleDetail
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL, @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'SaleDetail',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

-- Enable sales sync (head before detail via Priority in SyncConfig)
UPDATE dbo.SyncConfig SET IsEnabled = 1 WHERE TableName IN (N'SaleHead', N'SaleDetail');
GO

PRINT 'DataSync_05_Sales.sql completed.';
GO
