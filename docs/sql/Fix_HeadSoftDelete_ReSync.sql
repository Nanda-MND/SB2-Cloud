/*
  ============================================================================
  Head soft-delete re-sync (PurchaseHead + other *Head with Deleted)
  ============================================================================
  Cause: SyncApply_Generic UPDATE forced Deleted=0 / IsDeleted=0, undoing soft-delete
  after a later U. Fixed in DataSync_10_SyncApply_Generic.sql.

  Run AFTER deploying DataSync_10 on BOTH sides.

  Order:
    1) BOTH: DataSync_10_SyncApply_Generic.sql
    2) LOCAL: this script (cleanup + L2C requeue soft-deletes)
    3) CLOUD: this script (cleanup + C2L requeue soft-deletes)
    4) Rebuild/restart SyncAgent (Operation pass-through for Head)
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'============================================================';
PRINT N'Head soft-delete re-sync';
PRINT N'DB=' + DB_NAME() + N'  Server=' + @@SERVERNAME;
PRINT N'============================================================';
GO

PRINT N'--- A) SyncApply must NOT force Deleted=0 on UPDATE ---';
IF OBJECT_ID(N'dbo.SyncApply_Generic', N'P') IS NULL
BEGIN
    RAISERROR(N'STOP: SyncApply_Generic missing. Deploy DataSync_10 first.', 16, 1);
    RETURN;
END

SELECT
    CASE
        WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic'))
             LIKE N'%preserve-soft-delete-flags%'
            THEN N'OK_PRESERVE_DELETED'
        ELSE N'OLD — redeploy DataSync_10_SyncApply_Generic.sql'
    END AS ApplyVer;
GO

IF OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) NOT LIKE N'%preserve-soft-delete-flags%'
BEGIN
    RAISERROR(N'STOP: SyncApply still old (forces Deleted=0). Deploy DataSync_10_SyncApply_Generic.sql first.', 16, 1);
    RETURN;
END
GO

PRINT N'--- B) Soft-deleted Heads on this DB ---';
SELECT ID, Deleted, IsDeleted, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ISNULL(Deleted, 0) <> 0 OR ISNULL(IsDeleted, 0) <> 0
ORDER BY ID;
GO

PRINT N'--- C) Ensure IsDeleted mirrors Deleted (PurchaseHead) ---';
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = 1; END TRY BEGIN CATCH END CATCH;
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = 1; END TRY BEGIN CATCH END CATCH;

UPDATE dbo.PurchaseHead
SET IsDeleted = 1,
    DeletedAt = COALESCE(DeletedAt, SYSUTCDATETIME()),
    SyncModifiedAt = SYSUTCDATETIME()
WHERE ISNULL(Deleted, 0) <> 0
  AND ISNULL(IsDeleted, 0) = 0;
PRINT N'PurchaseHead IsDeleted mirrored: ' + CAST(@@ROWCOUNT AS nvarchar(20));

BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressOutbox', @value = NULL; END TRY BEGIN CATCH END CATCH;
BEGIN TRY EXEC sp_set_session_context @key = N'SyncSuppressMetadata', @value = NULL; END TRY BEGIN CATCH END CATCH;
GO

PRINT N'--- D) Requeue soft-delete outbox (Op=D or payload Deleted) ---';
IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NULL
    PRINT N'No SyncOutbox — skip D.';
ELSE
BEGIN
    DECLARE @dir nvarchar(3) =
        CASE WHEN DB_NAME() IN (N'SB1', N'SB') THEN N'L2C' ELSE N'C2L' END;

    -- Recent Head Op=D → Pending again
    UPDATE dbo.SyncOutbox
    SET Status = N'Pending',
        AttemptCount = 0,
        LastError = NULL,
        SyncedAt = NULL,
        SyncModifiedAt = SYSUTCDATETIME()
    WHERE Direction = @dir
      AND TableName LIKE N'%Head'
      AND Operation = N'D'
      AND Status IN (N'Synced', N'Conflict', N'DeadLetter', N'Syncing')
      AND CreatedAt >= DATEADD(day, -60, SYSUTCDATETIME());
    PRINT N'Requeued ' + @dir + N' *Head Op=D: ' + CAST(@@ROWCOUNT AS nvarchar(20));

    -- Fresh Op=D from currently soft-deleted PurchaseHead rows
    DELETE FROM dbo.SyncOutbox
    WHERE Direction = @dir
      AND TableName = N'PurchaseHead'
      AND Status = N'Pending'
      AND (PrimaryKeyJson LIKE N'%200000000%' OR PrimaryKeyJson LIKE N'%"ID":%')
      AND Operation = N'D';

    INSERT INTO dbo.SyncOutbox (Direction, TableName, PrimaryKeyJson, Operation, PayloadJson, SyncModifiedAt)
    SELECT
        @dir,
        N'PurchaseHead',
        (SELECT h.ID AS ID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        N'D',
        (SELECT h.ID, h.Deleted, IsDeleted = CAST(1 AS bit),
                h.SyncModifiedAt, h.SyncOrigin
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        h.SyncModifiedAt
    FROM dbo.PurchaseHead h
    WHERE ISNULL(h.Deleted, 0) <> 0 OR ISNULL(h.IsDeleted, 0) <> 0;

    PRINT N'Fresh ' + @dir + N' PurchaseHead Op=D: ' + CAST(@@ROWCOUNT AS nvarchar(20));

    SELECT Status, Operation, COUNT(*) Cnt
    FROM dbo.SyncOutbox
    WHERE Direction = @dir
      AND TableName = N'PurchaseHead'
      AND CreatedAt >= DATEADD(day, -2, SYSUTCDATETIME())
    GROUP BY Status, Operation
    ORDER BY Status, Operation;
END
GO

PRINT N'============================================================';
PRINT N'1) Deploy DataSync_10 on BOTH sides (preserve Deleted on U).';
PRINT N'2) Run this script on LOCAL then CLOUD.';
PRINT N'3) Rebuild SyncAgent + restart (Head @Operation).';
PRINT N'4) Verify other side: Deleted=1 / hidden in list.';
PRINT N'============================================================';
GO
