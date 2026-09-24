/*
  ============================================================================
  RUN PACK — LOCAL SB1
  User 14 / 16 changes FROM "disable Entry Edit" onward
  ============================================================================
  Idempotent: safe to re-run (0 rows / already-done = no error).

  Order on LOCAL:
    1) Disable Entry AllowEdit for User 14 + 16
    2) UserRights SyncConfig → L2C only (CaptureLocal=1, CaptureCloud=0)
    3) Deduplicate UserRights (UserID+MenuID+MenuSubID)

  Related (run on CLOUD separately):
    docs/sql/RunPack_Users14_16_Cloud.sql

  Earlier 14/16 scripts (already applied earlier — NOT in this pack):
    Clone_UserRights_14_to_16.sql
    Restrict_LogInClient_client1_Users14_16.sql
    Restrict_User14_Reports_StockBalanceOnly.sql
    Grant_UserRights_StockIssueByInvoice_14_16.sql
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT N'##############################';
PRINT N'# LOCAL PACK — ' + DB_NAME();
PRINT N'# Started: ' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126);
PRINT N'##############################';
GO

/* --------------------------------------------------------------------------
   1) Disable Entry Edit — User 14 / 16 (MenuID = 2, AllowEdit = 0)
   -------------------------------------------------------------------------- */
PRINT N'';
PRINT N'=== [1/3] Disable Entry Edit User 14/16 ===';

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 14)
    PRINT N'WARN: UserID 14 missing — skip edit disable for 14.';
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 16)
    PRINT N'WARN: UserID 16 missing — skip edit disable for 16.';

IF COL_LENGTH(N'dbo.UserRights', N'AllowEdit') IS NULL
BEGIN
    PRINT N'ERROR: UserRights.AllowEdit column missing — abort step 1.';
END
ELSE
BEGIN
    UPDATE dbo.UserRights
    SET AllowEdit = 0
    WHERE UserID IN (14, 16)
      AND MenuID = 2
      AND ISNULL(AllowEdit, 0) <> 0;

    PRINT N'AllowEdit→0 rows updated: ' + CAST(@@ROWCOUNT AS nvarchar(10))
        + N' (0 = already applied)';

    SELECT
        UR.UserID,
        EditOn = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 1 THEN 1 ELSE 0 END),
        EditOff = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 0 THEN 1 ELSE 0 END),
        TotalEntry = COUNT(*)
    FROM dbo.UserRights UR
    WHERE UR.UserID IN (14, 16)
      AND UR.MenuID = 2
    GROUP BY UR.UserID
    ORDER BY UR.UserID;
END
GO

/* --------------------------------------------------------------------------
   2) UserRights sync — L2C only on LOCAL
   -------------------------------------------------------------------------- */
PRINT N'';
PRINT N'=== [2/3] UserRights SyncConfig L2C-only (LOCAL) ===';

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
BEGIN
    PRINT N'WARN: SyncConfig missing — skip sync step.';
END
ELSE
BEGIN
    IF OBJECT_ID(N'dbo.tr_SyncOutbox_UserRights', N'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.tr_SyncOutbox_UserRights;
        PRINT N'Dropped tr_SyncOutbox_UserRights';
    END

    IF OBJECT_ID(N'dbo.tr_SyncCaptureCloud_UserRights', N'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.tr_SyncCaptureCloud_UserRights;
        PRINT N'Dropped tr_SyncCaptureCloud_UserRights';
    END

    IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'UserRights')
    BEGIN
        UPDATE dbo.SyncConfig
        SET IsEnabled = 1,
            CaptureLocal = 1,
            CaptureCloud = 0
        WHERE TableName = N'UserRights'
          AND (
                ISNULL(IsEnabled, 0) <> 1
             OR ISNULL(CaptureLocal, 0) <> 1
             OR ISNULL(CaptureCloud, 0) <> 0
          );

        PRINT N'SyncConfig UserRights updated rows: ' + CAST(@@ROWCOUNT AS nvarchar(10))
            + N' (0 = already L2C-only)';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.SyncConfig
            (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
        VALUES
            (N'UserRights', 1, 1, 0, N'ID', 100, 30, N'L2C only — RunPack Local');
        PRINT N'Inserted SyncConfig UserRights (L2C capture).';
    END

    SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
    FROM dbo.SyncConfig
    WHERE TableName = N'UserRights';
END
GO

/* --------------------------------------------------------------------------
   3) Deduplicate UserRights (all users / all MenuID)
   -------------------------------------------------------------------------- */
PRINT N'';
PRINT N'=== [3/3] Deduplicate UserRights ===';

DECLARE @DupCnt int =
(
    SELECT COUNT(*)
    FROM (
        SELECT UserID, MenuID, MenuSubID
        FROM dbo.UserRights
        GROUP BY UserID, MenuID, MenuSubID
        HAVING COUNT(*) > 1
    ) x
);
PRINT N'Duplicate keys before: ' + CAST(@DupCnt AS nvarchar(10));

IF @DupCnt = 0
    PRINT N'No duplicates — skip.';
ELSE
BEGIN
    BEGIN TRAN;

    IF COL_LENGTH(N'dbo.UserRights', N'SyncOrigin') IS NOT NULL
    BEGIN
        ;WITH ranked AS
        (
            SELECT
                ID,
                rn = ROW_NUMBER() OVER (
                    PARTITION BY UserID, MenuID, MenuSubID
                    ORDER BY
                        CASE WHEN SyncOrigin = 1 THEN 0 ELSE 1 END,
                        ID
                )
            FROM dbo.UserRights
        )
        DELETE FROM ranked WHERE rn > 1;
    END
    ELSE
    BEGIN
        ;WITH ranked AS
        (
            SELECT
                ID,
                rn = ROW_NUMBER() OVER (
                    PARTITION BY UserID, MenuID, MenuSubID
                    ORDER BY ID
                )
            FROM dbo.UserRights
        )
        DELETE FROM ranked WHERE rn > 1;
    END

    PRINT N'Deleted duplicate rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));
    COMMIT TRAN;
END

SELECT
    UR.UserID, UR.MenuID, UR.MenuSubID, Cnt = COUNT(*)
FROM dbo.UserRights UR
GROUP BY UR.UserID, UR.MenuID, UR.MenuSubID
HAVING COUNT(*) > 1;

PRINT N'';
PRINT N'=== LOCAL pack spot-check User 14/16 Entry AllowEdit (expect EditOn=0) ===';
SELECT
    UR.UserID,
    EditOn = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 1 THEN 1 ELSE 0 END),
    EditOff = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 0 THEN 1 ELSE 0 END),
    TotalEntry = COUNT(*)
FROM dbo.UserRights UR
WHERE UR.UserID IN (14, 16) AND UR.MenuID = 2
GROUP BY UR.UserID
ORDER BY UR.UserID;

PRINT N'LOCAL pack DONE. Re-login User 14/16. Then run RunPack_Users14_16_Cloud.sql on Cloud.';
GO
