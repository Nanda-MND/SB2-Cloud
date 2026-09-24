/*
  ============================================================================
  RUN PACK — CLOUD
  User 14 / 16 changes FROM "disable Entry Edit" onward
  ============================================================================
  Idempotent: safe to re-run (0 rows / already-done = no error).

  Order on CLOUD:
    1) Disable Entry AllowEdit for User 14 + 16 (match Local immediately)
    2) LogInClient.ID = 14 → allow ALL active users
    3) UserRights SyncConfig → L2C apply only (CaptureCloud=0, drop C2L trigger)
    4) Deduplicate UserRights

  Related (run on LOCAL separately):
    docs/sql/RunPack_Users14_16_Local.sql

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
PRINT N'# CLOUD PACK — ' + DB_NAME();
PRINT N'# Started: ' + CONVERT(nvarchar(30), SYSUTCDATETIME(), 126);
PRINT N'##############################';
GO

/* --------------------------------------------------------------------------
   1) Disable Entry Edit — User 14 / 16
   -------------------------------------------------------------------------- */
PRINT N'';
PRINT N'=== [1/4] Disable Entry Edit User 14/16 ===';

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 14)
    PRINT N'WARN: UserID 14 missing — skip.';
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 16)
    PRINT N'WARN: UserID 16 missing — skip.';

IF COL_LENGTH(N'dbo.UserRights', N'AllowEdit') IS NULL
    PRINT N'ERROR: UserRights.AllowEdit missing — abort step 1.';
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
    WHERE UR.UserID IN (14, 16) AND UR.MenuID = 2
    GROUP BY UR.UserID
    ORDER BY UR.UserID;
END
GO

/* --------------------------------------------------------------------------
   2) LogInClient.ID = 14 → all active users allowed
   -------------------------------------------------------------------------- */
PRINT N'';
PRINT N'=== [2/4] LogInClient ID 14 allow all active users ===';

IF OBJECT_ID(N'dbo.LogInClient', N'U') IS NULL
    OR OBJECT_ID(N'dbo.UserLoginInfo', N'U') IS NULL
BEGIN
    PRINT N'WARN: LogInClient / UserLoginInfo missing — skip login allow-all.';
END
ELSE IF NOT EXISTS (SELECT 1 FROM dbo.LogInClient WHERE ID = 14)
BEGIN
    PRINT N'WARN: LogInClient ID 14 not found — skip.';
END
ELSE
BEGIN
    DECLARE @LoginID int = 14;
    DECLARE @ClientName nvarchar(200) =
        (SELECT Name FROM dbo.LogInClient WHERE ID = @LoginID);

    PRINT N'LogInClient ID=14 Name=' + ISNULL(@ClientName, N'?');

    UPDATE dbo.UserLoginInfo
    SET isAllow = 1
    WHERE LoginID = @LoginID
      AND ISNULL(isAllow, 0) <> 1;

    PRINT N'Re-enabled rows: ' + CAST(@@ROWCOUNT AS nvarchar(10))
        + N' (0 = already allowed)';

    INSERT INTO dbo.UserLoginInfo (LoginID, UserID, isAllow)
    SELECT @LoginID, U.ID, 1
    FROM dbo.Users U
    WHERE ISNULL(U.InActive, 0) <> 1
      AND NOT EXISTS (
          SELECT 1 FROM dbo.UserLoginInfo F
          WHERE F.LoginID = @LoginID AND F.UserID = U.ID
      );

    PRINT N'Inserted missing users: ' + CAST(@@ROWCOUNT AS nvarchar(10))
        + N' (0 = already complete)';

    SELECT AllowedCnt = COUNT(*)
    FROM dbo.UserLoginInfo
    WHERE LoginID = @LoginID AND ISNULL(isAllow, 0) = 1;
END
GO

/* --------------------------------------------------------------------------
   3) UserRights — L2C apply only on CLOUD (no C2L capture)
   -------------------------------------------------------------------------- */
PRINT N'';
PRINT N'=== [3/4] UserRights SyncConfig L2C-only (CLOUD) ===';

IF OBJECT_ID(N'dbo.SyncConfig', N'U') IS NULL
    PRINT N'WARN: SyncConfig missing — skip.';
ELSE
BEGIN
    IF OBJECT_ID(N'dbo.tr_SyncOutbox_UserRights', N'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.tr_SyncOutbox_UserRights;
        PRINT N'Dropped tr_SyncOutbox_UserRights';
    END
    ELSE
        PRINT N'No tr_SyncOutbox_UserRights (ok).';

    IF OBJECT_ID(N'dbo.tr_SyncCaptureCloud_UserRights', N'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER dbo.tr_SyncCaptureCloud_UserRights;
        PRINT N'Dropped tr_SyncCaptureCloud_UserRights';
    END

    IF EXISTS (SELECT 1 FROM dbo.SyncConfig WHERE TableName = N'UserRights')
    BEGIN
        UPDATE dbo.SyncConfig
        SET IsEnabled = 1,
            CaptureLocal = 0,
            CaptureCloud = 0
        WHERE TableName = N'UserRights'
          AND (
                ISNULL(IsEnabled, 0) <> 1
             OR ISNULL(CaptureCloud, 0) <> 0
             OR ISNULL(CaptureLocal, 0) <> 0
          );

        PRINT N'SyncConfig updated rows: ' + CAST(@@ROWCOUNT AS nvarchar(10))
            + N' (0 = already L2C-apply-only)';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.SyncConfig
            (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)
        VALUES
            (N'UserRights', 1, 0, 0, N'ID', 100, 30, N'L2C inbound only — RunPack Cloud');
        PRINT N'Inserted SyncConfig UserRights.';
    END

    IF OBJECT_ID(N'dbo.SyncOutbox', N'U') IS NOT NULL
    BEGIN
        DELETE FROM dbo.SyncOutbox
        WHERE TableName = N'UserRights'
          AND Direction = N'C2L'
          AND Status IN (N'Pending', N'Syncing');
        PRINT N'Cleared pending C2L UserRights outbox: ' + CAST(@@ROWCOUNT AS nvarchar(10));
    END

    SELECT TableName, IsEnabled, CaptureLocal, CaptureCloud
    FROM dbo.SyncConfig
    WHERE TableName = N'UserRights';
END
GO

/* --------------------------------------------------------------------------
   4) Deduplicate UserRights
   -------------------------------------------------------------------------- */
PRINT N'';
PRINT N'=== [4/4] Deduplicate UserRights ===';

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

SELECT UR.UserID, UR.MenuID, UR.MenuSubID, Cnt = COUNT(*)
FROM dbo.UserRights UR
GROUP BY UR.UserID, UR.MenuID, UR.MenuSubID
HAVING COUNT(*) > 1;

PRINT N'';
PRINT N'=== CLOUD pack spot-check ===';
SELECT
    UR.UserID,
    EditOn = SUM(CASE WHEN ISNULL(UR.AllowEdit, 0) = 1 THEN 1 ELSE 0 END),
    TotalEntry = COUNT(*)
FROM dbo.UserRights UR
WHERE UR.UserID IN (14, 16) AND UR.MenuID = 2
GROUP BY UR.UserID
ORDER BY UR.UserID;

PRINT N'CLOUD pack DONE. Reopen login on LogInClient ID 14 PC; re-login User 14/16.';
GO
