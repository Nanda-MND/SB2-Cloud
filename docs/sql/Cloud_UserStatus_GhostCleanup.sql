/*
  ============================================================================
  CLOUD ONLY — Login ghost cleanup (UserStatus)
  ============================================================================
  Local uses master.dbo.StartUp → dbo.Waiter (infinite loop on SQL startup).
  Cloud must NOT run that Waiter/StartUp pattern.

  Why separate:
    - UserStatus is sync-disabled (DataSync_18) → Local/Cloud each have own rows
    - Cloud login ghosts only clear on the Cloud DB the client connects to

  What this does:
    - One-shot DELETE of UserStatus rows whose HostName is not in active
      .NET SQL client sessions on THIS database
    - No infinite loop (safe for Agent / Elastic Job / manual run)

  Schedule (pick one):
    A) SQL Server Agent (VM / Managed Instance): every 1–5 minutes
         EXEC dbo.UserStatus_CleanupGhosts;
    B) Azure SQL Database: Elastic Job / external scheduler same EXEC
    C) Manual: run when users stuck on "logged on by …"

  Do NOT:
    - EXEC Waiter on Cloud
    - Put this inside an infinite WHILE
    - Three-part name another DB (use current Cloud DB)
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.UserStatus', N'U') IS NULL
BEGIN
    RAISERROR(N'dbo.UserStatus not found — wrong database?', 16, 1);
    RETURN;
END
GO

CREATE OR ALTER PROCEDURE dbo.UserStatus_CleanupGhosts
AS
BEGIN
    SET NOCOUNT ON;

    /*
      Match Waiter intent, modern catalog:
      keep rows whose HostName still has a user session into this DB
      from common SqlClient program names.
    */
    DELETE us
    FROM dbo.UserStatus AS us
    WHERE us.HostName IS NOT NULL
      AND LTRIM(RTRIM(us.HostName)) <> N''
      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.dm_exec_sessions AS s
          WHERE s.is_user_process = 1
            AND s.database_id = DB_ID()
            AND s.host_name = us.HostName
            AND s.program_name IN
            (
                N'.Net SqlClient Data Provider',
                N'Core Microsoft SqlClient Data Provider',
                N'Microsoft SQL Server Data Provider',
                N'SqlClient'
            )
      );

    PRINT N'UserStatus_CleanupGhosts deleted rows: ' + CAST(@@ROWCOUNT AS nvarchar(20));
END
GO

-- Smoke run once after deploy
EXEC dbo.UserStatus_CleanupGhosts;
GO

/*
  Optional Agent step script body:
    EXEC dbo.UserStatus_CleanupGhosts;

  Verify stuck logins:
    SELECT * FROM dbo.UserStatus ORDER BY UserID;
    SELECT session_id, host_name, program_name, login_name
    FROM sys.dm_exec_sessions
    WHERE is_user_process = 1 AND database_id = DB_ID();
*/
