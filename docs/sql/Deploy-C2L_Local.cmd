@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM C2L deploy — LOCAL ONLY (Server\SB1 / SB1)
REM Applies Cloud changes to Local when Sync Agent pulls C2L.
REM Run on office PC (must reach local SQL).

set SERVER=Server\SB1
set DATABASE=SB1
set SQLUSER=sa
set /p SQLPASS=Enter sa password: 

set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === C2L deploy: LOCAL %SERVER% / %DATABASE% ===
echo.

echo Running DataSync_10_SyncApply_Generic.sql ...
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "DataSync_10_SyncApply_Generic.sql"
if errorlevel 1 (
  echo FAILED on DataSync_10_SyncApply_Generic.sql
  pause
  exit /b 1
)

echo.
echo === Verify L2C capture still active (CaptureLocal=1) ===
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -Q "SELECT COUNT(*) AS L2C_CaptureLocal FROM dbo.SyncConfig WHERE IsEnabled=1 AND CaptureLocal=1; SELECT COUNT(*) AS L2C_Triggers FROM sys.triggers WHERE name LIKE 'tr_SyncOutbox_%';"

echo.
echo === Verify C2L apply side (Local should NOT capture C2L) ===
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -i "Check-C2LStatus.sql"

echo.
echo Local C2L deploy completed.
echo Next: rebuild SB.SyncAgent, copy to ERP folder, net stop/start SB.SyncAgent
pause
