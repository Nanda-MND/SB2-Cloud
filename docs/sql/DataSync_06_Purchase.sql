/*
  Data Sync - Purchase (PurchaseHead + PurchaseDetail)
  Run on BOTH Local and Cloud databases.
  Prerequisites: DataSync_01, DataSync_03 already applied.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- SyncConfig seed
MERGE dbo.SyncConfig AS t
USING (VALUES
    (N'PurchaseHead',   1, 1, 0, N'ID',  50, 22, N'Purchase header'),
    (N'PurchaseDetail', 1, 1, 0, N'ID', 100, 23, N'Purchase lines')
) AS s(TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
ON t.TableName = s.TableName
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
    VALUES (s.TableName, s.IsEnabled, s.CaptureLocal, s.CaptureCloud, s.PrimaryKeyColumns, s.BatchSize, s.Priority, s.Notes)
WHEN MATCHED THEN
    UPDATE SET IsEnabled = s.IsEnabled, CaptureLocal = s.CaptureLocal, BatchSize = s.BatchSize, Priority = s.Priority;
GO

-- ========== PurchaseHead sync columns ==========
IF COL_LENGTH('dbo.PurchaseHead', 'IsDeleted') IS NULL
    ALTER TABLE dbo.PurchaseHead ADD IsDeleted bit NOT NULL CONSTRAINT DF_PurchaseHead_IsDeleted DEFAULT (0);
GO
IF COL_LENGTH('dbo.PurchaseHead', 'DeletedAt') IS NULL
    ALTER TABLE dbo.PurchaseHead ADD DeletedAt datetime2(3) NULL;
GO
IF COL_LENGTH('dbo.PurchaseHead', 'DeletedBy') IS NULL
    ALTER TABLE dbo.PurchaseHead ADD DeletedBy int NULL;
GO
IF COL_LENGTH('dbo.PurchaseHead', 'SyncModifiedAt') IS NULL
    ALTER TABLE dbo.PurchaseHead ADD SyncModifiedAt datetime2(3) NOT NULL CONSTRAINT DF_PurchaseHead_SyncMod DEFAULT (sysutcdatetime());
GO
IF COL_LENGTH('dbo.PurchaseHead', 'SyncModifiedBy') IS NULL
    ALTER TABLE dbo.PurchaseHead ADD SyncModifiedBy int NULL;
GO
IF COL_LENGTH('dbo.PurchaseHead', 'SyncOrigin') IS NULL
    ALTER TABLE dbo.PurchaseHead ADD SyncOrigin tinyint NOT NULL CONSTRAINT DF_PurchaseHead_SyncOrigin DEFAULT (1);
GO
IF COL_LENGTH('dbo.PurchaseHead', 'SyncRowVersion') IS NULL
    ALTER TABLE dbo.PurchaseHead ADD SyncRowVersion rowversion;
GO

EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
UPDATE dbo.PurchaseHead
SET IsDeleted = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN 1 ELSE 0 END,
    DeletedAt = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN ISNULL(DeletedAt, SyncModifiedAt) ELSE NULL END
WHERE IsDeleted = 0 AND ISNULL(Deleted, 0) <> 0;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
GO

-- ========== PurchaseDetail sync columns ==========
IF COL_LENGTH('dbo.PurchaseDetail', 'IsDeleted') IS NULL
    ALTER TABLE dbo.PurchaseDetail ADD IsDeleted bit NOT NULL CONSTRAINT DF_PurchaseDetail_IsDeleted DEFAULT (0);
GO
IF COL_LENGTH('dbo.PurchaseDetail', 'DeletedAt') IS NULL
    ALTER TABLE dbo.PurchaseDetail ADD DeletedAt datetime2(3) NULL;
GO
IF COL_LENGTH('dbo.PurchaseDetail', 'DeletedBy') IS NULL
    ALTER TABLE dbo.PurchaseDetail ADD DeletedBy int NULL;
GO
IF COL_LENGTH('dbo.PurchaseDetail', 'SyncModifiedAt') IS NULL
    ALTER TABLE dbo.PurchaseDetail ADD SyncModifiedAt datetime2(3) NOT NULL CONSTRAINT DF_PurchaseDetail_SyncMod DEFAULT (sysutcdatetime());
GO
IF COL_LENGTH('dbo.PurchaseDetail', 'SyncModifiedBy') IS NULL
    ALTER TABLE dbo.PurchaseDetail ADD SyncModifiedBy int NULL;
GO
IF COL_LENGTH('dbo.PurchaseDetail', 'SyncOrigin') IS NULL
    ALTER TABLE dbo.PurchaseDetail ADD SyncOrigin tinyint NOT NULL CONSTRAINT DF_PurchaseDetail_SyncOrigin DEFAULT (1);
GO
IF COL_LENGTH('dbo.PurchaseDetail', 'SyncRowVersion') IS NULL
    ALTER TABLE dbo.PurchaseDetail ADD SyncRowVersion rowversion;
GO

-- Metadata triggers
IF OBJECT_ID('dbo.tr_PurchaseHead_SyncMetadata', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_PurchaseHead_SyncMetadata;
GO
CREATE TRIGGER dbo.tr_PurchaseHead_SyncMetadata ON dbo.PurchaseHead AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
        WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1))) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE h SET h.SyncModifiedAt = sysutcdatetime(), h.SyncModifiedBy = COALESCE(i.SyncModifiedBy, h.SyncModifiedBy)
    FROM dbo.PurchaseHead h INNER JOIN inserted i ON i.ID = h.ID
    LEFT JOIN deleted d ON d.ID = i.ID
    WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1));
END
GO

IF OBJECT_ID('dbo.tr_PurchaseDetail_SyncMetadata', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_PurchaseDetail_SyncMetadata;
GO
CREATE TRIGGER dbo.tr_PurchaseDetail_SyncMetadata ON dbo.PurchaseDetail AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
        WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1))) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE d SET d.SyncModifiedAt = sysutcdatetime(), d.SyncModifiedBy = COALESCE(i.SyncModifiedBy, d.SyncModifiedBy)
    FROM dbo.PurchaseDetail d INNER JOIN inserted i ON i.ID = d.ID
    LEFT JOIN deleted del ON del.ID = i.ID
    WHERE del.ID IS NULL OR (i.SyncModifiedAt = del.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(del.SyncModifiedBy,-1));
END
GO

IF OBJECT_ID('dbo.tr_PurchaseHead_SoftDeleteSync', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_PurchaseHead_SoftDeleteSync;
GO
CREATE TRIGGER dbo.tr_PurchaseHead_SoftDeleteSync ON dbo.PurchaseHead AFTER UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i INNER JOIN deleted d ON d.ID = i.ID WHERE ISNULL(i.Deleted,0) <> 0 AND ISNULL(d.Deleted,0) = 0) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE h SET h.IsDeleted = 1, h.DeletedAt = COALESCE(h.DeletedAt, sysutcdatetime())
    FROM dbo.PurchaseHead h INNER JOIN inserted i ON i.ID = h.ID
    WHERE ISNULL(i.Deleted,0) <> 0 AND ISNULL(h.IsDeleted,0) = 0;
END
GO

-- Outbox capture
IF OBJECT_ID('dbo.tr_SyncOutbox_PurchaseHead', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncOutbox_PurchaseHead;
GO
CREATE TRIGGER dbo.tr_SyncOutbox_PurchaseHead ON dbo.PurchaseHead AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressOutbox') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'PurchaseHead' AND IsEnabled = 1 AND CaptureLocal = 1) RETURN;
    ;WITH changed AS (
        SELECT i.ID,
            Operation = CASE WHEN d.ID IS NULL THEN 'I'
                WHEN ISNULL(i.IsDeleted,0) = 1 AND ISNULL(d.IsDeleted,0) = 0 THEN 'D' ELSE 'U' END,
            PayloadJson = (SELECT i.ID, i.Date, i.AutoID, i.DocumentID, i.StockReceived, i.LocationID, i.SupplierID,
                i.CurrencyID, i.PaymentID, i.AccountID, i.ExgRate, i.Remark, i.Balance, i.Amount, i.Discount,
                i.NetAmount, i.TaxAmount, i.TotalAmount, i.PaidAmount, i.TotalBalance, i.UserID, i.EditDate, i.Invoice,
                Deleted = ISNULL(i.Deleted,0), IsDeleted = ISNULL(i.IsDeleted,0),
                i.SyncModifiedAt, i.SyncModifiedBy, i.SyncOrigin
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            PrimaryKeyJson = (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
        FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT 'L2C', N'PurchaseHead', c.PrimaryKeyJson, c.Operation, c.PayloadJson, c.SyncModifiedAt FROM changed c
    WHERE NOT EXISTS (SELECT 1 FROM dbo.SyncOutbox o WHERE o.Direction='L2C' AND o.TableName=N'PurchaseHead'
        AND o.PrimaryKeyJson = c.PrimaryKeyJson AND o.Status='Pending' AND o.CreatedAt > DATEADD(second,-1,sysutcdatetime()));
END
GO

IF OBJECT_ID('dbo.tr_SyncOutbox_PurchaseDetail', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncOutbox_PurchaseDetail;
GO
CREATE TRIGGER dbo.tr_SyncOutbox_PurchaseDetail ON dbo.PurchaseDetail AFTER INSERT, UPDATE, DELETE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressOutbox') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'PurchaseDetail' AND IsEnabled = 1 AND CaptureLocal = 1) RETURN;
    ;WITH changed AS (
        SELECT src.ID, src.Operation, src.PayloadJson, src.PrimaryKeyJson, src.SyncModifiedAt FROM (
            SELECT i.ID,
                Operation = CASE WHEN d.ID IS NULL THEN 'I'
                    WHEN ISNULL(i.IsDeleted,0) = 1 AND ISNULL(d.IsDeleted,0) = 0 THEN 'D' ELSE 'U' END,
                PayloadJson = (SELECT i.ID, i.RefID, i.Sr, i.CodeID, i.BrandID, i.UnitID, i.Qty, i.Weight, i.Price,
                    i.TotalWeight, i.Amount, i.Qty1, i.Qty2, i.Remark, i.PurchaseID,
                    IsDeleted = ISNULL(i.IsDeleted,0), i.SyncModifiedAt, i.SyncModifiedBy, i.SyncOrigin
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                PrimaryKeyJson = (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
            FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
            UNION ALL
            SELECT d.ID, Operation = 'D',
                PayloadJson = (SELECT d.ID, d.RefID, d.Sr, d.CodeID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                PrimaryKeyJson = (SELECT d.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                SyncModifiedAt = sysutcdatetime()
            FROM deleted d WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.ID = d.ID)
        ) src
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT 'L2C', N'PurchaseDetail', c.PrimaryKeyJson, c.Operation, c.PayloadJson, c.SyncModifiedAt FROM changed c
    WHERE NOT EXISTS (SELECT 1 FROM dbo.SyncOutbox o WHERE o.Direction='L2C' AND o.TableName=N'PurchaseDetail'
        AND o.PrimaryKeyJson = c.PrimaryKeyJson AND o.Status='Pending' AND o.CreatedAt > DATEADD(second,-1,sysutcdatetime()));
END
GO

IF OBJECT_ID('dbo.tr_SyncBlockDelete_PurchaseHead', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncBlockDelete_PurchaseHead;
GO
CREATE TRIGGER dbo.tr_SyncBlockDelete_PurchaseHead ON dbo.PurchaseHead INSTEAD OF DELETE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncAllowPhysicalDelete') = 1 BEGIN DELETE h FROM dbo.PurchaseHead h INNER JOIN deleted d ON d.ID = h.ID; RETURN; END
    RAISERROR(N'Physical DELETE blocked on PurchaseHead. Use soft delete (Deleted=1).', 16, 1);
END
GO

-- Apply procedures (delegate to SyncApply_Generic)
IF OBJECT_ID('dbo.SyncApply_PurchaseHead', 'P') IS NOT NULL DROP PROCEDURE dbo.SyncApply_PurchaseHead;
GO
CREATE PROCEDURE dbo.SyncApply_PurchaseHead
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL, @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'PurchaseHead',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

IF OBJECT_ID('dbo.SyncApply_PurchaseDetail', 'P') IS NOT NULL DROP PROCEDURE dbo.SyncApply_PurchaseDetail;
GO
CREATE PROCEDURE dbo.SyncApply_PurchaseDetail
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL, @Operation char(1) = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN
    EXEC dbo.SyncApply_Generic
        @Source = @Source,
        @TableName = N'PurchaseDetail',
        @PayloadJson = @PayloadJson,
        @PrimaryKeyJson = @PrimaryKeyJson,
        @RemoteModifiedAt = @RemoteModifiedAt,
        @Operation = @Operation,
        @OutboxID = @OutboxID,
        @ConflictLogged = @ConflictLogged OUTPUT,
        @Applied = @Applied OUTPUT;
END
GO

UPDATE dbo.SyncConfig SET IsEnabled = 1 WHERE TableName IN (N'PurchaseHead', N'PurchaseDetail');
GO

PRINT 'DataSync_06_Purchase.sql completed.';
GO
