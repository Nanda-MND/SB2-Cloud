@echo off
REM ============================================================================
REM INSTALL — register Task Scheduler job (every 3 minutes)
REM ============================================================================
REM Run this once as Administrator (right-click → Run as administrator).
REM It creates a Windows task that calls:
REM   Cloud_UserStatus_CleanupGhosts_TaskScheduler.cmd
REM
REM Prerequisites:
REM   1. Edit PASSWORD in Cloud_UserStatus_CleanupGhosts_TaskScheduler.cmd
REM   2. sqlcmd available on PATH
REM   3. Cloud SP dbo.UserStatus_CleanupGhosts already created
REM ============================================================================

setlocal
cd /d "%~dp0"

set "TASK_NAME=SB_Cloud_UserStatus_CleanupGhosts"
set "CMD_FILE=%~dp0Cloud_UserStatus_CleanupGhosts_TaskScheduler.cmd"

if not exist "%CMD_FILE%" (
  echo Missing: %CMD_FILE%
  exit /b 1
)

REM Remove old task if present
schtasks /Query /TN "%TASK_NAME%" >nul 2>&1
if not errorlevel 1 (
  echo Removing existing task %TASK_NAME% ...
  schtasks /Delete /TN "%TASK_NAME%" /F >nul
)

REM Create: every 3 minutes, indefinitely
REM /SC MINUTE /MO 3 = every 3 minutes
REM /RU SYSTEM = runs even if nobody logged on (needs Admin)
echo Creating task %TASK_NAME% ...
schtasks /Create ^
  /TN "%TASK_NAME%" ^
  /TR "\"%CMD_FILE%\"" ^
  /SC MINUTE ^
  /MO 3 ^
  /RU SYSTEM ^
  /RL HIGHEST ^
  /F

if errorlevel 1 (
  echo.
  echo FAILED — open Command Prompt as Administrator and run this Install again.
  echo Or create the task manually in Task Scheduler GUI.
  exit /b 1
)

echo.
echo OK — task created: %TASK_NAME%
echo Check: Task Scheduler Library → %TASK_NAME%
echo Run once now:
schtasks /Run /TN "%TASK_NAME%"
echo.
echo List:
schtasks /Query /TN "%TASK_NAME%" /V /FO LIST | findstr /I "TaskName Status Last Run Next Schedule"
echo.
echo Done.
endlocal
