/*
  Data Sync — Change capture trigger TEMPLATE
  Replace @TableName and column list per table.
  Run on LOCAL first (L2C). Enable CaptureCloud tables on Cloud for C2L.

  Example: Customer table pilot
  PREREQUISITE: Run DataSync_04 soft-delete columns on Customer first.
*/

SET NOCOUNT ON;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('dbo.tr_SyncOutbox_Customer', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_SyncOutbox_Customer;
GO

CREATE TRIGGER dbo.tr_SyncOutbox_Customer
ON dbo.Customer
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF SESSION_CONTEXT(N'SyncSuppressOutbox') = 1
        RETURN;

    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'Customer' AND IsEnabled = 1 AND CaptureLocal = 1)
        RETURN;

    ;WITH changed AS (
        SELECT
            i.ID,
            Operation = CASE
                WHEN d.ID IS NULL THEN 'I'
                WHEN ISNULL(i.IsDeleted, 0) = 1 AND ISNULL(d.IsDeleted, 0) = 0 THEN 'D'
                ELSE 'U'
            END,
            PayloadJson = (
                SELECT
                    i.ID, i.Short, i.Name, i.TownshipID, i.DivID,
                    IsDeleted = ISNULL(i.IsDeleted, 0),
                    Deleted = ISNULL(i.Deleted, 0),
                    i.DeletedAt, i.DeletedBy,
                    i.SyncModifiedAt, i.SyncModifiedBy, i.SyncOrigin
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ),
            PrimaryKeyJson = (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
        FROM inserted i
        LEFT JOIN deleted d ON d.ID = i.ID
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT
        'L2C',
        N'Customer',
        c.PrimaryKeyJson,
        c.Operation,
        c.PayloadJson,
        c.SyncModifiedAt
    FROM changed c
    WHERE NOT EXISTS (
        -- coalesce rapid duplicate updates within same second (optional dedupe)
        SELECT 1 FROM dbo.SyncOutbox o
        WHERE o.Direction = 'L2C'
          AND o.TableName = N'Customer'
          AND o.PrimaryKeyJson = c.PrimaryKeyJson
          AND o.Status = 'Pending'
          AND o.CreatedAt > DATEADD(second, -1, sysutcdatetime())
    );
END
GO

/*
  BLOCK physical DELETE on synced tables (soft delete only)
*/
IF OBJECT_ID('dbo.tr_SyncBlockDelete_Customer', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_SyncBlockDelete_Customer;
GO

CREATE TRIGGER dbo.tr_SyncBlockDelete_Customer
ON dbo.Customer
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF SESSION_CONTEXT(N'SyncAllowPhysicalDelete') = 1
    BEGIN
        DELETE c FROM dbo.Customer c INNER JOIN deleted d ON d.ID = c.ID;
        RETURN;
    END

    RAISERROR(N'Physical DELETE blocked on Customer. Use soft delete (Deleted=1 / IsDeleted=1).', 16, 1);
END
GO

PRINT 'DataSync_02_ChangeCapture_Template.sql completed (Customer pilot).';
GO
