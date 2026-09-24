/*
  Restrict LogInClient 'client-1' so ONLY UserID 14 can appear / log in.

  SUPERSEDED: use Restrict_LogInClient_client1_Users14_16.sql
  when client-1 should allow both User 14 and User 16.

  Run on the DB that client-1 connects to (usually Cloud).
  PC Windows computer name must equal LogInClient.Name = N'client-1'.
*/

SET NOCOUNT ON;

DECLARE @ClientName sysname = N'client-1';
DECLARE @UserID int = 14;
DECLARE @LoginID int;

SELECT @LoginID = ID
FROM dbo.LogInClient
WHERE Name = @ClientName;

IF @LoginID IS NULL
BEGIN
    RAISERROR(N'LogInClient [%s] not found. Check exact Windows computer name.', 16, 1, @ClientName);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @UserID AND ISNULL(InActive,0) <> 1)
BEGIN
    RAISERROR(N'UserID %d missing or InActive.', 16, 1, @UserID);
    RETURN;
END

PRINT 'LogInClient ID=' + CAST(@LoginID AS nvarchar(10)) + N' Name=' + @ClientName;

BEGIN TRAN;

-- Deny everyone else on this client
UPDATE dbo.UserLoginInfo
SET isAllow = 0
WHERE LoginID = @LoginID
  AND UserID <> @UserID;

-- Ensure user 14 row exists and allowed
IF EXISTS (SELECT 1 FROM dbo.UserLoginInfo WHERE LoginID = @LoginID AND UserID = @UserID)
    UPDATE dbo.UserLoginInfo SET isAllow = 1
    WHERE LoginID = @LoginID AND UserID = @UserID;
ELSE
    INSERT INTO dbo.UserLoginInfo (LoginID, UserID, isAllow)
    VALUES (@LoginID, @UserID, 1);

COMMIT TRAN;

PRINT '=== Allowed users on client-1 (should be User 14 only) ===';
SELECT L.Name AS ClientName, U.ID AS UserID, U.Name AS UserName, F.isAllow, U.InActive
FROM dbo.LogInClient L
JOIN dbo.UserLoginInfo F ON F.LoginID = L.ID
JOIN dbo.Users U ON U.ID = F.UserID
WHERE L.ID = @LoginID
  AND ISNULL(F.isAllow, 0) = 1
ORDER BY U.ID;
GO
