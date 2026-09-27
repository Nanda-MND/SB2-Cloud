@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM Option C — Cloud: C2L master data only (disable transaction C2L)

set SERVER=SQL1002.site4now.net
set DATABASE=db_abbe78_warehouse
set SQLUSER=db_abbe78_warehouse_admin
set /p SQLPASS=Enter cloud SQL password: 

set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === Option C: Disable C2L for transactions (CLOUD) ===
echo.

sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "DataSync_31_DisableC2L_Transactions.sql"
if errorlevel 1 (
  echo FAILED
  pause
  exit /b 1
)

echo.
echo Done. Home: edit master data only. Vouchers: office Local only.
pause
