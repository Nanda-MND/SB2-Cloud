/*
  Diagnose why Users dropdown is empty on PC "client-9".

  Login loads:
    Users JOIN UserLoginInfo JOIN LogInClient
    WHERE InActive<>1 AND isAllow=1 AND LogInClient.Name = Windows Computer Name

  Run on the DB that client-9 connects to (usually Cloud).
*/

SET NOCOUNT ON;

DECLARE @WantedName nvarchar(128) = N'client-9';

PRINT N'=== 1) LogInClient rows matching client-9 ===';
SELECT ID, Name, DefaultPrinter
FROM dbo.LogInClient
WHERE Name = @WantedName
   OR Name LIKE N'%client%9%'
   OR Name LIKE N'%CLIENT%9%'
ORDER BY ID;

IF NOT EXISTS (SELECT 1 FROM dbo.LogInClient WHERE Name = @WantedName)
BEGIN
    PRINT N'FAIL: No LogInClient.Name = ''client-9''.';
    PRINT N'Fix: set this PC Windows name to match an existing LogInClient.Name,';
    PRINT N'      OR insert LogInClient with Name = exact Windows computer name.';
    PRINT N'Nearby LogInClient names:';
    SELECT TOP 30 ID, Name FROM dbo.LogInClient ORDER BY Name;
END
ELSE
    PRINT N'OK: LogInClient Name=client-9 exists.';

PRINT N'=== 2) UserLoginInfo for client-9 ===';
SELECT
    L.ID AS LoginID,
    L.Name AS ClientName,
    F.UserID,
    U.Name AS UserName,
    F.isAllow,
    U.InActive
FROM dbo.LogInClient L
LEFT JOIN dbo.UserLoginInfo F ON F.LoginID = L.ID
LEFT JOIN dbo.Users U ON U.ID = F.UserID
WHERE L.Name = @WantedName
ORDER BY U.Name;

PRINT N'=== 3) What login dropdown would show (same query as frm_Login) ===';
SELECT U.ID, U.Name
FROM dbo.Users U
JOIN dbo.UserLoginInfo F ON U.ID = F.UserID
JOIN dbo.LogInClient L ON F.LoginID = L.ID
WHERE ISNULL(U.InActive, 0) <> 1
  AND ISNULL(F.isAllow, 0) = 1
  AND L.Name = @WantedName
ORDER BY U.Name;

PRINT N'=== 4) Counts ===';
SELECT
    ActiveUsers = (SELECT COUNT(*) FROM dbo.Users WHERE ISNULL(InActive,0) <> 1),
    AllowedOnClient9 =
        (SELECT COUNT(*)
         FROM dbo.Users U
         JOIN dbo.UserLoginInfo F ON U.ID = F.UserID
         JOIN dbo.LogInClient L ON F.LoginID = L.ID
         WHERE L.Name = @WantedName
           AND ISNULL(U.InActive,0) <> 1
           AND ISNULL(F.isAllow,0) = 1);

PRINT N'If section 3 is empty → run AllowAllUsers_LogInClient_client9.sql on THIS DB.';
GO
