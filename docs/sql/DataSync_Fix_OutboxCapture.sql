/*
  Fix: SyncOutbox empty after ERP Customer edit.
  Cause: tr_Customer_SyncMetadata was blocking tr_SyncOutbox_Customer.
  Run on Local SB1 database.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- 1) Verify setup
SELECT 'SyncConfig' AS CheckName, TableName, IsEnabled, CaptureLocal
FROM dbo.SyncConfig WHERE TableName = N'Customer';

SELECT 'Triggers' AS CheckName, name, is_disabled
FROM sys.triggers
WHERE parent_id = OBJECT_ID('dbo.Customer');
GO

-- 2) Fix metadata trigger (do NOT suppress outbox)
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

-- 3) Ensure outbox trigger exists
IF OBJECT_ID('dbo.tr_SyncOutbox_Customer', 'TR') IS NULL
BEGIN
    RAISERROR('Missing tr_SyncOutbox_Customer. Run DataSync_02_ChangeCapture_Template.sql first.', 16, 1);
END
GO

-- 4) Manual test (creates one outbox row)
UPDATE dbo.Customer SET Name = Name WHERE ID = (SELECT MIN(ID) FROM dbo.Customer);
GO

SELECT TOP 3 OutboxID, Direction, TableName, Operation, Status, CreatedAt
FROM dbo.SyncOutbox ORDER BY OutboxID DESC;
GO

PRINT 'Fix applied. Edit a Customer in ERP and check SyncOutbox again.';
GO
