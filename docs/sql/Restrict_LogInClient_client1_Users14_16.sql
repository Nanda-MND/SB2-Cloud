/*
  Restrict LogInClient 'client-1' so ONLY UserID 14 and 16 can appear / log in.

  Run on the DB that client-1 connects to (usually Cloud).
  PC Windows computer name must equal LogInClient.Name = N'client-1'.

  Supersedes Restrict_LogInClient_client1_User14.sql (User 14 only).
*/

SET NOCOUNT ON;

DECLARE @ClientName sysname = N'client-1';
DECLARE @LoginID int;

SELECT @LoginID = ID
FROM dbo.LogInClient
WHERE Name = @ClientName;

IF @LoginID IS NULL
BEGIN
    RAISERROR(N'LogInClient [%s] not found. Check exact Windows computer name.', 16, 1, @ClientName);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 14 AND ISNULL(InActive,0) <> 1)
BEGIN
    RAISERROR(N'UserID 14 missing or InActive.', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE ID = 16 AND ISNULL(InActive,0) <> 1)
BEGIN
    RAISERROR(N'UserID 16 missing or InActive.', 16, 1);
    RETURN;
END

PRINT 'LogInClient ID=' + CAST(@LoginID AS nvarchar(10)) + N' Name=' + @ClientName;

BEGIN TRAN;

-- Deny everyone except 14 and 16 on this client
UPDATE dbo.UserLoginInfo
SET isAllow = 0
WHERE LoginID = @LoginID
  AND UserID NOT IN (14, 16);

-- Ensure user 14 row exists and allowed
IF EXISTS (SELECT 1 FROM dbo.UserLoginInfo WHERE LoginID = @LoginID AND UserID = 14)
    UPDATE dbo.UserLoginInfo SET isAllow = 1
    WHERE LoginID = @LoginID AND UserID = 14;
ELSE
    INSERT INTO dbo.UserLoginInfo (LoginID, UserID, isAllow)
    VALUES (@LoginID, 14, 1);

-- Ensure user 16 row exists and allowed
IF EXISTS (SELECT 1 FROM dbo.UserLoginInfo WHERE LoginID = @LoginID AND UserID = 16)
    UPDATE dbo.UserLoginInfo SET isAllow = 1
    WHERE LoginID = @LoginID AND UserID = 16;
ELSE
    INSERT INTO dbo.UserLoginInfo (LoginID, UserID, isAllow)
    VALUES (@LoginID, 16, 1);

COMMIT TRAN;

PRINT '=== Allowed users on client-1 (should be User 14 and 16 only) ===';
SELECT L.Name AS ClientName, U.ID AS UserID, U.Name AS UserName, F.isAllow, U.InActive
FROM dbo.LogInClient L
JOIN dbo.UserLoginInfo F ON F.LoginID = L.ID
JOIN dbo.Users U ON U.ID = F.UserID
WHERE L.ID = @LoginID
  AND ISNULL(F.isAllow, 0) = 1
ORDER BY U.ID;
GO
