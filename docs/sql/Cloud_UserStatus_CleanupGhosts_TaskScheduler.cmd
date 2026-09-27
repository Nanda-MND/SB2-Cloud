@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM ============================================================================
REM Cloud UserStatus ghost cleanup — no msdb / no SQL Agent
REM ============================================================================
REM For Azure SQL / site4now (no msdb): schedule THIS .cmd with Windows
REM Task Scheduler every 3 minutes on any always-on PC that can reach Cloud.
REM
REM Setup:
REM   1. Cloud DB: run docs\sql\Cloud_UserStatus_GhostCleanup.sql once
REM   2. Edit SERVER / DATABASE / USER / PASSWORD below (or set env vars)
REM   3. Register schedule (Admin CMD):
REM        Cloud_UserStatus_CleanupGhosts_InstallTask.cmd
REM      OR Task Scheduler GUI — this .cmd alone does NOT create a task.
REM
REM Requires: sqlcmd (SSMS / sqlcmd tools) on the PC PATH

setlocal

if not defined CLOUD_SQL_SERVER set "CLOUD_SQL_SERVER=SQL1002.site4now.net"
if not defined CLOUD_SQL_DATABASE set "CLOUD_SQL_DATABASE=db_abbe78_warehouse"
if not defined CLOUD_SQL_USER set "CLOUD_SQL_USER=db_abbe78_warehouse_admin"
if not defined CLOUD_SQL_PASSWORD set "CLOUD_SQL_PASSWORD=YOUR_CLOUD_PASSWORD"

if "%CLOUD_SQL_PASSWORD%"=="YOUR_CLOUD_PASSWORD" (
  echo Edit PASSWORD in this file or set CLOUD_SQL_PASSWORD env var.
  exit /b 1
)

sqlcmd -S "%CLOUD_SQL_SERVER%" -d "%CLOUD_SQL_DATABASE%" -U "%CLOUD_SQL_USER%" -P "%CLOUD_SQL_PASSWORD%" -C -I -Q "EXEC dbo.UserStatus_CleanupGhosts;" -b
set ERR=%ERRORLEVEL%
echo [%DATE% %TIME%] UserStatus_CleanupGhosts exit=%ERR%
exit /b %ERR%
