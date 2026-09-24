/*
  ============================================================================
  CLOUD — schedule UserStatus_CleanupGhosts every 3 minutes
  ============================================================================
  Requires:
    - dbo.UserStatus_CleanupGhosts already created
      (run Cloud_UserStatus_GhostCleanup.sql first)
    - SQL Server Agent + msdb (VM / Managed Instance only)

  *** site4now / Azure SQL Database: msdb မရှိ ***
  ဒီ script မrunရ။ အစား:
    docs/sql/Cloud_UserStatus_CleanupGhosts_TaskScheduler.cmd
    → Windows Task Scheduler (every 3 minutes) + sqlcmd

  Run this script while connected to the CLOUD database
  (or edit @DbName below) — ONLY if msdb exists.
*/

SET NOCOUNT ON;
GO

USE msdb;
GO

DECLARE @JobName   sysname = N'UserStatus_CleanupGhosts_3min';
DECLARE @DbName    sysname = DB_NAME(); -- change if you ran from wrong DB: N'YourCloudDB'
DECLARE @StepName  sysname = N'Exec UserStatus_CleanupGhosts';
DECLARE @Schedule  sysname = N'Every_3_Minutes';
DECLARE @JobId     uniqueidentifier;
DECLARE @SchedId   int;

-- If you created the proc in another DB, set @DbName explicitly:
-- SET @DbName = N'SB_Cloud';

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name = @JobName,
        @enabled = 1,
        @description = N'Clear login ghosts in UserStatus every 3 minutes (Cloud).',
        @owner_login_name = NULL,
        @job_id = @JobId OUTPUT;
END
ELSE
BEGIN
    SELECT @JobId = job_id FROM msdb.dbo.sysjobs WHERE name = @JobName;
END

-- Replace step if re-run
IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobsteps
    WHERE job_id = @JobId AND step_name = @StepName
)
BEGIN
    EXEC msdb.dbo.sp_delete_jobstep @job_id = @JobId, @step_name = @StepName;
END

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = @StepName,
    @subsystem = N'TSQL',
    @database_name = @DbName,
    @command = N'EXEC dbo.UserStatus_CleanupGhosts;',
    @on_success_action = 1, -- quit success
    @on_fail_action = 2;    -- quit fail

-- Schedule every 3 minutes, daily forever
IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobschedules js
    JOIN msdb.dbo.sysschedules s ON s.schedule_id = js.schedule_id
    WHERE js.job_id = @JobId AND s.name = @Schedule
)
BEGIN
    SELECT @SchedId = s.schedule_id
    FROM msdb.dbo.sysjobschedules js
    JOIN msdb.dbo.sysschedules s ON s.schedule_id = js.schedule_id
    WHERE js.job_id = @JobId AND s.name = @Schedule;

    EXEC msdb.dbo.sp_detach_schedule
        @job_id = @JobId,
        @schedule_id = @SchedId,
        @delete_unused_schedule = 1;
END

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = @Schedule,
    @freq_type = 4,              -- daily
    @freq_interval = 1,          -- every day
    @freq_subday_type = 4,       -- minutes
    @freq_subday_interval = 3,   -- every 3 minutes
    @active_start_time = 0;      -- 00:00:00

EXEC msdb.dbo.sp_attach_schedule
    @job_name = @JobName,
    @schedule_name = @Schedule;

EXEC msdb.dbo.sp_add_jobserver
    @job_name = @JobName,
    @server_name = N'(local)';

-- Start once now (optional)
EXEC msdb.dbo.sp_start_job @job_name = @JobName;

PRINT N'Job ready: ' + @JobName + N' on DB ' + @DbName + N' every 3 minutes.';
GO

/*
  Check:
    SELECT j.name, j.enabled, s.name AS ScheduleName,
           s.freq_subday_type, s.freq_subday_interval
    FROM msdb.dbo.sysjobs j
    JOIN msdb.dbo.sysjobschedules js ON js.job_id = j.job_id
    JOIN msdb.dbo.sysschedules s ON s.schedule_id = js.schedule_id
    WHERE j.name = N'UserStatus_CleanupGhosts_3min';

  History:
    EXEC msdb.dbo.sp_help_jobhistory @job_name = N'UserStatus_CleanupGhosts_3min';

  Stop / disable:
    EXEC msdb.dbo.sp_update_job @job_name = N'UserStatus_CleanupGhosts_3min', @enabled = 0;
*/
