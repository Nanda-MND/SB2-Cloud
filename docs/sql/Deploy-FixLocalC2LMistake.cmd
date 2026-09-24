@echo off
REM Fix mistaken C2L deploy on Local — restore L2C capture

set SERVER=Server\SB1
set DATABASE=SB1
set SQLUSER=sa
set /p SQLPASS=Enter sa password: 

set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === Restore Local L2C after mistaken DataSync_29 ===
echo.

sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "DataSync_30_RestoreLocalL2C_AfterC2LMistake.sql"
if errorlevel 1 (
  echo FAILED
  pause
  exit /b 1
)

echo.
echo Local L2C restored. DataSync_10 on Local is OK — no need to re-run.
pause
