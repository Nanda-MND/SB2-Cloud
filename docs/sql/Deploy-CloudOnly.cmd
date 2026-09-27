@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM Run ALL required Cloud sync scripts (receive-only side).
REM Does NOT install Local capture triggers.

set SERVER=SQL1002.site4now.net
set DATABASE=db_abbe78_warehouse
set SQLUSER=db_abbe78_warehouse_admin
set /p SQLPASS=Cloud password: 

cd /d "%~dp0"

echo === Cloud sync structure deploy ===

for %%F in (
  DataSync_01_Schema.sql
  DataSync_04_SoftDelete_Migration.sql
  DataSync_03_ApplyInbound.sql
) do (
  echo Running %%F ...
  sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "%%F"
  if errorlevel 1 goto fail
)

echo.
echo Running verify ...
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -i DataSync_Cloud_Verify.sql

echo.
echo Cloud structure updated. Re-save a Customer in ERP on Local to test.
goto end

:fail
echo FAILED
pause
exit /b 1

:end
pause
