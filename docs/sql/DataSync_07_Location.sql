/*
  Data Sync - Location (master data)
  Run on BOTH Local and Cloud databases.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

MERGE dbo.SyncConfig AS t
USING (VALUES
    (N'Location', 1, 1, 0, N'ID', 100, 11, N'Warehouse/branch locations')
) AS s(TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
ON t.TableName = s.TableName
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
    VALUES (s.TableName, s.IsEnabled, s.CaptureLocal, s.CaptureCloud, s.PrimaryKeyColumns, s.BatchSize, s.Priority, s.Notes)
WHEN MATCHED THEN
    UPDATE SET IsEnabled = s.IsEnabled, CaptureLocal = s.CaptureLocal, Priority = s.Priority;
GO

-- Sync columns
IF COL_LENGTH('dbo.Location', 'IsDeleted') IS NULL
    ALTER TABLE dbo.Location ADD IsDeleted bit NOT NULL CONSTRAINT DF_Location_IsDeleted DEFAULT (0);
GO
IF COL_LENGTH('dbo.Location', 'DeletedAt') IS NULL
    ALTER TABLE dbo.Location ADD DeletedAt datetime2(3) NULL;
GO
IF COL_LENGTH('dbo.Location', 'DeletedBy') IS NULL
    ALTER TABLE dbo.Location ADD DeletedBy int NULL;
GO
IF COL_LENGTH('dbo.Location', 'SyncModifiedAt') IS NULL
    ALTER TABLE dbo.Location ADD SyncModifiedAt datetime2(3) NOT NULL CONSTRAINT DF_Location_SyncMod DEFAULT (sysutcdatetime());
GO
IF COL_LENGTH('dbo.Location', 'SyncModifiedBy') IS NULL
    ALTER TABLE dbo.Location ADD SyncModifiedBy int NULL;
GO
IF COL_LENGTH('dbo.Location', 'SyncOrigin') IS NULL
    ALTER TABLE dbo.Location ADD SyncOrigin tinyint NOT NULL CONSTRAINT DF_Location_SyncOrigin DEFAULT (1);
GO
IF COL_LENGTH('dbo.Location', 'SyncRowVersion') IS NULL
    ALTER TABLE dbo.Location ADD SyncRowVersion rowversion;
GO

EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1;
UPDATE dbo.Location
SET IsDeleted = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN 1 ELSE 0 END,
    DeletedAt = CASE WHEN ISNULL(Deleted, 0) <> 0 THEN ISNULL(DeletedAt, SyncModifiedAt) ELSE NULL END
WHERE IsDeleted = 0 AND ISNULL(Deleted, 0) <> 0;
EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL;
EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL;
GO

IF OBJECT_ID('dbo.tr_Location_SyncMetadata', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_Location_SyncMetadata;
GO
CREATE TRIGGER dbo.tr_Location_SyncMetadata ON dbo.Location AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
        WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1))) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE l SET l.SyncModifiedAt = sysutcdatetime(), l.SyncModifiedBy = COALESCE(i.SyncModifiedBy, l.SyncModifiedBy)
    FROM dbo.Location l INNER JOIN inserted i ON i.ID = l.ID
    LEFT JOIN deleted d ON d.ID = i.ID
    WHERE d.ID IS NULL OR (i.SyncModifiedAt = d.SyncModifiedAt AND ISNULL(i.SyncModifiedBy,-1) = ISNULL(d.SyncModifiedBy,-1));
END
GO

IF OBJECT_ID('dbo.tr_Location_SoftDeleteSync', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_Location_SoftDeleteSync;
GO
CREATE TRIGGER dbo.tr_Location_SoftDeleteSync ON dbo.Location AFTER UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressMetadata') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i INNER JOIN deleted d ON d.ID = i.ID WHERE ISNULL(i.Deleted,0) <> 0 AND ISNULL(d.Deleted,0) = 0) RETURN;
    EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1;
    UPDATE l SET l.IsDeleted = 1, l.DeletedAt = COALESCE(l.DeletedAt, sysutcdatetime())
    FROM dbo.Location l INNER JOIN inserted i ON i.ID = l.ID
    WHERE ISNULL(i.Deleted,0) <> 0 AND ISNULL(l.IsDeleted,0) = 0;
END
GO

IF OBJECT_ID('dbo.tr_SyncOutbox_Location', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncOutbox_Location;
GO
CREATE TRIGGER dbo.tr_SyncOutbox_Location ON dbo.Location AFTER INSERT, UPDATE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncSuppressOutbox') = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'Location' AND IsEnabled = 1 AND CaptureLocal = 1) RETURN;
    ;WITH changed AS (
        SELECT i.ID,
            Operation = CASE WHEN d.ID IS NULL THEN 'I'
                WHEN ISNULL(i.IsDeleted,0) = 1 AND ISNULL(d.IsDeleted,0) = 0 THEN 'D' ELSE 'U' END,
            PayloadJson = (SELECT i.ID, i.Short, i.Name, i.TypeID, i.SortID,
                Deleted = ISNULL(i.Deleted,0), IsDeleted = ISNULL(i.IsDeleted,0),
                i.SyncModifiedAt, i.SyncModifiedBy, i.SyncOrigin
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            PrimaryKeyJson = (SELECT i.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            SyncModifiedAt = ISNULL(i.SyncModifiedAt, sysutcdatetime())
        FROM inserted i LEFT JOIN deleted d ON d.ID = i.ID
    )
    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT 'L2C', N'Location', c.PrimaryKeyJson, c.Operation, c.PayloadJson, c.SyncModifiedAt FROM changed c
    WHERE NOT EXISTS (SELECT 1 FROM dbo.SyncOutbox o WHERE o.Direction='L2C' AND o.TableName=N'Location'
        AND o.PrimaryKeyJson = c.PrimaryKeyJson AND o.Status='Pending' AND o.CreatedAt > DATEADD(second,-1,sysutcdatetime()));
END
GO

IF OBJECT_ID('dbo.tr_SyncBlockDelete_Location', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_SyncBlockDelete_Location;
GO
CREATE TRIGGER dbo.tr_SyncBlockDelete_Location ON dbo.Location INSTEAD OF DELETE AS
BEGIN SET NOCOUNT ON;
    IF SESSION_CONTEXT(N'SyncAllowPhysicalDelete') = 1 BEGIN DELETE l FROM dbo.Location l INNER JOIN deleted d ON d.ID = l.ID; RETURN; END
    RAISERROR(N'Physical DELETE blocked on Location. Use soft delete (Deleted=1).', 16, 1);
END
GO

IF OBJECT_ID('dbo.SyncApply_Location', 'P') IS NOT NULL DROP PROCEDURE dbo.SyncApply_Location;
GO
CREATE PROCEDURE dbo.SyncApply_Location
    @Source varchar(10), @PayloadJson nvarchar(max), @RemoteModifiedAt datetime2(3),
    @PrimaryKeyJson nvarchar(500), @OutboxID bigint = NULL,
    @ConflictLogged bit OUTPUT, @Applied bit OUTPUT
AS
BEGIN SET NOCOUNT ON; SET @ConflictLogged = 0; SET @Applied = 0;
    DECLARE @ID int = JSON_VALUE(@PrimaryKeyJson, '$.ID');
    IF @Source = 'Cloud' BEGIN
        DECLARE @LocalMod datetime2(3);
        SELECT @LocalMod = SyncModifiedAt FROM dbo.Location WHERE ID = @ID;
        IF @LocalMod IS NOT NULL AND @LocalMod > @RemoteModifiedAt BEGIN
            INSERT INTO dbo.SyncConflictLog (Direction, TableName, PrimaryKeyJson, Resolution, RemoteModifiedAt, LocalModifiedAt, RemotePayloadJson, Message)
            VALUES ('C2L', N'Location', @PrimaryKeyJson, 'LocalWinsSkipped', @RemoteModifiedAt, @LocalMod, @PayloadJson, N'Local Location is newer.');
            SET @ConflictLogged = 1; RETURN;
        END
    END
    IF ISNULL((SELECT CAST(JSON_VALUE(@PayloadJson, '$.IsDeleted') AS bit)), 0) = 1
       OR ISNULL((SELECT CAST(JSON_VALUE(@PayloadJson, '$.Deleted') AS bit)), 0) = 1
    BEGIN
        UPDATE dbo.Location SET IsDeleted = 1, Deleted = 1, DeletedAt = @RemoteModifiedAt,
            SyncModifiedAt = @RemoteModifiedAt, SyncOrigin = CASE WHEN @Source = 'Local' THEN 1 ELSE 2 END WHERE ID = @ID;
        SET @Applied = 1; RETURN;
    END
    UPDATE l SET
        l.Short = j.Short, l.Name = j.Name, l.TypeID = j.TypeID, l.SortID = j.SortID,
        l.SyncModifiedAt = @RemoteModifiedAt, l.SyncOrigin = CASE WHEN @Source = 'Local' THEN 1 ELSE 2 END,
        l.IsDeleted = 0, l.Deleted = 0
    FROM dbo.Location l
    INNER JOIN OPENJSON(@PayloadJson) WITH (
        ID int, Short nvarchar(50), Name nvarchar(200), TypeID int, SortID int
    ) j ON l.ID = j.ID WHERE l.ID = @ID;
    IF @@ROWCOUNT = 0 AND @Source = 'Local'
    BEGIN
        SET IDENTITY_INSERT dbo.Location ON;
        INSERT INTO dbo.Location (ID, Short, Name, TypeID, SortID, SyncModifiedAt, SyncOrigin, IsDeleted, Deleted)
        SELECT j.ID, j.Short, j.Name, j.TypeID, j.SortID, @RemoteModifiedAt, 1, 0, 0
        FROM OPENJSON(@PayloadJson) WITH (
            ID int, Short nvarchar(50), Name nvarchar(200), TypeID int, SortID int
        ) j WHERE NOT EXISTS (SELECT 1 FROM dbo.Location x WHERE x.ID = j.ID);
        SET IDENTITY_INSERT dbo.Location OFF;
    END
    SET @Applied = 1;
END
GO

UPDATE dbo.SyncConfig SET IsEnabled = 1 WHERE TableName = N'Location';
GO

PRINT 'DataSync_07_Location.sql completed.';
GO
