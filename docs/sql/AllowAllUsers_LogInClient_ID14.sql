/*
  LogInClient.ID = 14 → allow ALL active users to appear / log in.

  Ensures every non-InActive user has UserLoginInfo(LoginID=14, isAllow=1).
  Existing denied rows for this client are re-enabled.

  Run on the DB that this client connects to (usually Cloud / Local matching that PC).
*/

SET NOCOUNT ON;

DECLARE @LoginID int = 14;
DECLARE @ClientName nvarchar(200);

SELECT @ClientName = Name
FROM dbo.LogInClient
WHERE ID = @LoginID;

IF @ClientName IS NULL
BEGIN
    RAISERROR(N'LogInClient ID %d not found.', 16, 1, @LoginID);
    RETURN;
END

PRINT N'LogInClient ID=' + CAST(@LoginID AS nvarchar(10)) + N' Name=' + @ClientName;

PRINT N'=== BEFORE: allowed user count ===';
SELECT AllowedCnt = COUNT(*)
FROM dbo.UserLoginInfo
WHERE LoginID = @LoginID
  AND ISNULL(isAllow, 0) = 1;

BEGIN TRAN;

-- Re-enable every existing UserLoginInfo row for this client
UPDATE dbo.UserLoginInfo
SET isAllow = 1
WHERE LoginID = @LoginID
  AND ISNULL(isAllow, 0) <> 1;

PRINT N'Re-enabled existing rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

-- Insert missing rows for all active users
INSERT INTO dbo.UserLoginInfo (LoginID, UserID, isAllow)
SELECT
    @LoginID,
    U.ID,
    1
FROM dbo.Users U
WHERE ISNULL(U.InActive, 0) <> 1
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.UserLoginInfo F
      WHERE F.LoginID = @LoginID
        AND F.UserID = U.ID
  );

PRINT N'Inserted missing user rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

COMMIT TRAN;

PRINT N'=== AFTER: allowed users on LogInClient ID 14 ===';
SELECT
    L.ID AS LoginID,
    L.Name AS ClientName,
    U.ID AS UserID,
    U.Name AS UserName,
    F.isAllow,
    U.InActive
FROM dbo.LogInClient L
JOIN dbo.UserLoginInfo F ON F.LoginID = L.ID
JOIN dbo.Users U ON U.ID = F.UserID
WHERE L.ID = @LoginID
  AND ISNULL(F.isAllow, 0) = 1
ORDER BY U.ID;

PRINT N'Done. All active users can log in on LogInClient ID 14 (' + @ClientName + N').';
PRINT N'Restart / reopen login form on that PC to refresh the user list.';
GO
