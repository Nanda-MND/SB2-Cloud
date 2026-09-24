/*
  Data Sync — Soft delete & sync metadata columns (TEMPLATE per table)
  Run per business table on Local AND Cloud before enabling sync triggers.

  Maps existing ERP pattern: Deleted = 1  →  IsDeleted / DeletedAt / DeletedBy
*/

SET NOCOUNT ON;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ========== EXAMPLE: Customer ==========
IF COL_LENGTH('dbo.Customer', 'IsDeleted') IS NULL
    ALTER TABLE dbo.Customer ADD IsDeleted bit NOT NULL CONSTRAINT DF_Customer_IsDeleted DEFAULT (0);
GO

IF COL_LENGTH('dbo.Customer', 'DeletedAt') IS NULL
    ALTER TABLE dbo.Customer ADD DeletedAt datetime2(3) NULL;
GO

IF COL_LENGTH('dbo.Customer', 'DeletedBy') IS NULL
    ALTER TABLE dbo.Customer ADD DeletedBy int NULL;
GO

IF COL_LENGTH('dbo.Customer', 'SyncModifiedAt') IS NULL
    ALTER TABLE dbo.Customer ADD SyncModifiedAt datetime2(3) NOT NULL CONSTRAINT DF_Customer_SyncMod DEFAULT (sysutcdatetime());
GO

IF COL_LENGTH('dbo.Customer', 'SyncModifiedBy') IS NULL
    ALTER TABLE dbo.Customer ADD SyncModifiedBy int NULL;
GO

IF COL_LENGTH('dbo.Customer', 'SyncOrigin') IS NULL
    ALTER TABLE dbo.Customer ADD SyncOrigin tinyint NOT NULL CONSTRAINT DF_Customer_SyncOrigin DEFAULT (1); -- 1=Local
GO

IF COL_LENGTH('dbo.Customer', 'SyncRowVersion') IS NULL
    ALTER TABLE dbo.Customer ADD SyncRowVersion rowversion;
GO

-- Backfill from existing Deleted flag (suppress triggers during one-time migration)
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
UPDATE dbo.Customer
SET IsDeleted = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN 1 ELSE 0 END,
    DeletedAt = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN ISNULL(DeletedAt, SyncModifiedAt) ELSE NULL END
WHERE IsDeleted = 0 AND ISNULL(Deleted, 0) <> 0;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
GO

-- Keep IsDeleted in sync when legacy app sets Deleted = 1
IF OBJECT_ID('dbo.tr_Customer_SoftDeleteSync', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Customer_SoftDeleteSync;
GO

CREATE TRIGGER dbo.tr_Customer_SoftDeleteSync
ON dbo.Customer
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1
        RETURN;

    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d ON d.ID = i.ID
        WHERE ISNULL(i.Deleted, 0) <> 0 AND ISNULL(d.Deleted, 0) = 0
    )
        RETURN;

    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;

    UPDATE c SET
        c.IsDeleted  = 1,
        c.DeletedAt  = COALESCE(c.DeletedAt, i.DeletedAt, sysutcdatetime()),
        c.DeletedBy  = COALESCE(c.DeletedBy, i.DeletedBy, i.SyncModifiedBy)
    FROM dbo.Customer c
    INNER JOIN inserted i ON i.ID = c.ID
    WHERE ISNULL(i.Deleted, 0) <> 0
      AND ISNULL(c.IsDeleted, 0) = 0;
END
GO

-- Stamp SyncModifiedAt / SyncModifiedBy on every change (for conflict detection)
IF OBJECT_ID('dbo.tr_Customer_SyncMetadata', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Customer_SyncMetadata;
GO

CREATE TRIGGER dbo.tr_Customer_SyncMetadata
ON dbo.Customer
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1
        RETURN;

    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN deleted d ON d.ID = i.ID
        WHERE d.ID IS NULL
           OR (i.SyncModifiedAt = d.SyncModifiedAt
               AND ISNULL(i.SyncModifiedBy, -1) = ISNULL(d.SyncModifiedBy, -1))
    )
        RETURN;

    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;

    UPDATE c SET
        c.SyncModifiedAt = sysutcdatetime(),
        c.SyncModifiedBy = COALESCE(i.SyncModifiedBy, c.SyncModifiedBy)
    FROM dbo.Customer c
    INNER JOIN inserted i ON i.ID = c.ID
    LEFT JOIN deleted d ON d.ID = c.ID
    WHERE d.ID IS NULL
       OR (i.SyncModifiedAt = d.SyncModifiedAt
           AND ISNULL(i.SyncModifiedBy, -1) = ISNULL(d.SyncModifiedBy, -1));
END
GO

/*
  REPEAT the same pattern for other synced tables:
  SaleHead, SaleDetail, PurchaseHead, Location, Stock, Supplier, ...

  Transaction head tables: add DeletedBy from LocalData.UserID in app later,
  or infer from EditUserID if already present.
*/

PRINT 'DataSync_04_SoftDelete_Migration.sql completed (Customer pilot).';
GO
