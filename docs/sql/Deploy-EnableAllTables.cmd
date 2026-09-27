@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
setlocal EnableExtensions
REM Enable ALL ERP table sync + seed existing rows on Local.
REM Run on CLIENT PC. SyncAgent can keep running.

set "SCRIPTDIR=%~dp0"
cd /d "%SCRIPTDIR%"

echo.
echo === Enable All Table Data Sync ===
echo.

set "LOCAL_SERVER=Server\SB1"
set "LOCAL_DB=SB1"
set "LOCAL_USER=sa"
set /p "LOCAL_PASS=Enter Local sa password: "

echo.
echo Step 1: Core schema + apply procs...
call :RunSql "DataSync_01_Schema.sql" ""
if errorlevel 1 goto FAIL
call :RunSql "DataSync_03_ApplyInbound.sql" ""
if errorlevel 1 goto FAIL
call :RunSql "DataSync_10_SyncApply_Generic.sql" ""
if errorlevel 1 goto FAIL

echo.
echo Step 2: Install ALL tables - triggers + SyncConfig...
call :RunSql "DataSync_11_AllTables_Install.sql" ""
if errorlevel 1 goto FAIL
call :RunSql "DataSync_11_RunInstall.sql" "InstallCapture=1"
if errorlevel 1 goto FAIL

echo.
echo Step 3: Manufacturing + transaction tables...
call :RunSql "DataSync_15_ERPTransactionTables.sql" "InstallCapture=1"
if errorlevel 1 goto FAIL

echo.
echo Step 4: Sync priorities...
call :RunSql "DataSync_14_MasterPriority.sql" ""
if errorlevel 1 goto FAIL

echo.
echo Step 5: Enabled table count...
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -W -Q "SELECT COUNT(*) AS EnabledTables FROM dbo.SyncConfig WHERE IsEnabled=1; SELECT COUNT(*) AS OutboxTriggers FROM sys.triggers WHERE name LIKE 'tr_SyncOutbox_%';"

echo.
echo Step 6: Coverage report...
call :RunSql "DataSync_17_CoverageReport.sql" ""

echo.
set /p "DOSEED=Seed existing rows for NEW tables into Outbox? Y/N: "
if /i not "%DOSEED%"=="Y" goto SKIPSEED

echo Seeding - NEW tables only, batch 200...
call :RunSql "DataSync_13_InitialSeed.sql" ""
if errorlevel 1 goto FAIL
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -Q "EXEC dbo.SyncSeed_NewTablesOnly @BatchSize = 200;"
if errorlevel 1 goto FAIL
goto SKIPSEED

:SKIPSEED
echo.
echo LOCAL done.
echo Run on CLOUD with InstallCapture=0:
echo   DataSync_01, 03, 10, 11, 15, 14
echo.
echo SyncAgent will drain new Pending rows automatically.
goto DONE

:RunSql
set "SQLFILE=%~1"
set "SQLVARS=%~2"
echo   Running %SQLFILE% ...
if "%SQLVARS%"=="" (
    sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -I -b -i "%SQLFILE%"
) else (
    sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -I -b -v %SQLVARS% -i "%SQLFILE%"
)
exit /b %ERRORLEVEL%

:FAIL
echo.
echo FAILED. Check errors above.
pause
exit /b 1

:DONE
pause
exit /b 0
