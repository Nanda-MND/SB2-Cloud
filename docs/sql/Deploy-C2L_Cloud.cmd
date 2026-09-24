@echo off
REM C2L deploy — CLOUD ONLY (db_abbe78_warehouse)
REM Home insert/update → Cloud SyncOutbox (C2L) → Office Sync Agent → Local
REM Run from any PC that can reach site4now (home or office).

set SERVER=SQL1002.site4now.net
set DATABASE=db_abbe78_warehouse
set SQLUSER=db_abbe78_warehouse_admin
set /p SQLPASS=Enter cloud SQL password: 

set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === C2L deploy: CLOUD %SERVER% / %DATABASE% ===
echo.

for %%F in (
  DataSync_28_EnableC2L_Capture.sql
  DataSync_29_EnableAllC2L_Capture.sql
  DataSync_10_SyncApply_Generic.sql
  DataSync_21_EnableAllCloudInbound.sql
) do (
  echo Running %%F ...
  sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "%%F"
  if errorlevel 1 (
    echo FAILED on %%F
    pause
    exit /b 1
  )
)

echo.
echo === Verify C2L on Cloud ===
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -i "Check-C2LStatus.sql"

echo.
echo Cloud C2L deploy completed.
echo Next: run Deploy-C2L_Local.cmd on office PC, then rebuild + restart SB.SyncAgent.
pause
