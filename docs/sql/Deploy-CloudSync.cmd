@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM Run from YOUR PC (SSMS network) or any machine that can reach site4now Cloud SQL.

set SERVER=SQL1002.site4now.net
set DATABASE=db_abbe78_warehouse
set SQLUSER=db_abbe78_warehouse_admin
set /p SQLPASS=Enter cloud SQL password: 

set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === Data Sync deploy: Cloud %SERVER% / %DATABASE% ===
echo.

for %%F in (
  DataSync_01_Schema.sql
  DataSync_03_ApplyInbound.sql
  DataSync_10_SyncApply_Generic.sql
  DataSync_05_Sales.sql
  DataSync_06_Purchase.sql
) do (
  echo Running %%F ...
  sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "%%F"
  if errorlevel 1 (
    echo FAILED on %%F
    pause
    exit /b 1
  )
)

echo Running DataSync_11_AllTables_Install.sql (InstallCapture=0) ...
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -v InstallCapture=0 -i "DataSync_11_AllTables_Install.sql"
if errorlevel 1 (
  echo FAILED on DataSync_11_AllTables_Install.sql
  pause
  exit /b 1
)

echo Running DataSync_14_MasterPriority.sql ...
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "DataSync_14_MasterPriority.sql"
if errorlevel 1 (
  echo FAILED on DataSync_14_MasterPriority.sql
  pause
  exit /b 1
)

echo.
echo === Verify ===
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -Q "SELECT TableName, IsEnabled FROM dbo.SyncConfig WHERE IsEnabled=1; SELECT OBJECT_ID('dbo.SyncApply_Customer','P') AS SyncApply_Customer;"

echo.
echo Cloud sync SQL completed successfully.
pause
