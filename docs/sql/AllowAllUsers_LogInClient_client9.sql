/*
  ============================================================================
  Allow ALL active users on LogInClient Name = N'client-9'
  ============================================================================
  Fixes empty User dropdown on PC whose Windows name is "client-9".

  Run on the DB that client-9 connects to (usually Cloud warehouse).
  Then close/reopen SB login on that PC.

  Login filter (frm_Login):
    Users + UserLoginInfo.isAllow=1 + LogInClient.Name = Environment.MachineName
*/

SET NOCOUNT ON;

DECLARE @ClientName nvarchar(128) = N'client-9';
DECLARE @LoginID int;

SELECT @LoginID = ID
FROM dbo.LogInClient
WHERE Name = @ClientName;

IF @LoginID IS NULL
BEGIN
    /* Register PC if missing (same pattern as other clients) */
    IF COL_LENGTH(N'dbo.LogInClient', N'DefaultPrinter') IS NOT NULL
        INSERT INTO dbo.LogInClient (Name, DefaultPrinter)
        VALUES (@ClientName, 0);
    ELSE
        INSERT INTO dbo.LogInClient (Name)
        VALUES (@ClientName);

    SELECT @LoginID = ID FROM dbo.LogInClient WHERE Name = @ClientName;
    PRINT N'Inserted LogInClient Name=' + @ClientName + N' ID=' + CAST(@LoginID AS nvarchar(20));
END
ELSE
    PRINT N'Found LogInClient ID=' + CAST(@LoginID AS nvarchar(20)) + N' Name=' + @ClientName;

PRINT N'=== BEFORE: allowed user count ===';
SELECT AllowedCnt = COUNT(*)
FROM dbo.UserLoginInfo
WHERE LoginID = @LoginID
  AND ISNULL(isAllow, 0) = 1;

BEGIN TRAN;

UPDATE dbo.UserLoginInfo
SET isAllow = 1
WHERE LoginID = @LoginID
  AND ISNULL(isAllow, 0) <> 1;

PRINT N'Re-enabled: ' + CAST(@@ROWCOUNT AS nvarchar(20));

INSERT INTO dbo.UserLoginInfo (LoginID, UserID, isAllow)
SELECT
    @LoginID,
    U.ID,
    1
FROM dbo.Users U
WHERE ISNULL(U.InActive, 0) <> 1
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.UserLoginInfo F
      WHERE F.LoginID = @LoginID
        AND F.UserID = U.ID
  );

PRINT N'Inserted: ' + CAST(@@ROWCOUNT AS nvarchar(20));

COMMIT TRAN;

PRINT N'=== AFTER: users that will appear on client-9 login ===';
SELECT
    L.ID AS LoginID,
    L.Name AS ClientName,
    U.ID AS UserID,
    U.Name AS UserName,
    F.isAllow
FROM dbo.LogInClient L
JOIN dbo.UserLoginInfo F ON F.LoginID = L.ID
JOIN dbo.Users U ON U.ID = F.UserID
WHERE L.ID = @LoginID
  AND ISNULL(F.isAllow, 0) = 1
  AND ISNULL(U.InActive, 0) <> 1
ORDER BY U.Name;

PRINT N'Done. On client-9 PC: close SB → reopen login. User list should fill.';
PRINT N'If still empty: Windows computer name must be exactly ''client-9'' (see Diagnose script).';
GO
