@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM Full DB sync — Local seed + service start helper (client PC).
set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === Full DB Sync (Local) ===
echo.

set SERVER=Server\SB1
set DATABASE=SB1
set SQLUSER=sa
set /p SQLPASS=Enter Local sa password: 

echo.
echo Step 1: Update SyncClaimOutboxBatch + priorities (re-run schema procs)...
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "DataSync_03_ApplyInbound.sql"
if errorlevel 1 goto FAIL

sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "DataSync_14_MasterPriority.sql"
if errorlevel 1 goto FAIL

echo.
set /p "DOSEED=Seed missing rows into Outbox? Y/N: "
if /i not "%DOSEED%"=="Y" goto SKIPSEED
echo Seeding outbox...
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "DataSync_13_InitialSeed.sql"
if errorlevel 1 goto FAIL
:SKIPSEED

echo.
echo Step 2: Current backlog...
set SQLPASS=%SQLPASS%
set NO_PAUSE=1
call "%SCRIPTDIR%Monitor-SyncProgress.cmd"
set NO_PAUSE=

echo.
echo Step 3: Start Sync Agent service (if installed)...
net start SB.SyncAgent 2>nul
if errorlevel 1 (
  echo Service not running. Install with:
  echo   cd /d D:\MinnNandar\Software
  echo   InstallUtil.exe /i SB.SyncAgent.exe
  echo   net start SB.SyncAgent
  echo.
  echo Or drain manually: SB.SyncAgent.exe /drain 480
) else (
  echo SB.SyncAgent service started.
)

goto DONE

:FAIL
echo.
echo FAILED. Check errors above.
pause
exit /b 1

:DONE
echo.
echo Full sync helper finished. Re-run Monitor-SyncProgress.cmd to watch backlog drain.
pause
