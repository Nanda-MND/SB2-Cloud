@echo off
REM Deploy generic sync for ALL ERP tables (Local + Cloud).
REM Run on CLIENT PC / Server where SQL is reachable.

set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === All Tables Sync Deploy ===
echo.

set /p TARGET=Deploy to [L]ocal, [C]loud, or [B]oth? (default L): 
if /i "%TARGET%"=="" set TARGET=L
if /i "%TARGET%"=="B" goto BOTH
if /i "%TARGET%"=="C" goto CLOUD
goto LOCAL

:LOCAL
set SERVER=Server\SB1
set DATABASE=SB1
set SQLUSER=sa
set /p SQLPASS=Enter Local sa password: 
echo.
echo --- Local: schema + capture triggers ---
call :RUNSCRIPTS "%SERVER%" "%DATABASE%" "%SQLUSER%" "%SQLPASS%" 1
if errorlevel 1 goto FAIL
goto DONE

:CLOUD
set SERVER=SQL1002.site4now.net
set DATABASE=db_abbe78_warehouse
set SQLUSER=db_abbe78_warehouse_admin
set /p SQLPASS=Enter Cloud password: 
echo.
echo --- Cloud: schema only (no capture triggers) ---
call :RUNSCRIPTS "%SERVER%" "%DATABASE%" "%SQLUSER%" "%SQLPASS%" 0
if errorlevel 1 goto FAIL
goto DONE

:BOTH
set /p SQLPASS=Enter Local sa password: 
echo.
echo --- Local ---
call :RUNSCRIPTS "Server\SB1" "SB1" "sa" "%SQLPASS%" 1
if errorlevel 1 goto FAIL
set /p CLOUDPASS=Enter Cloud password: 
echo.
echo --- Cloud ---
call :RUNSCRIPTS "SQL1002.site4now.net" "db_abbe78_warehouse" "db_abbe78_warehouse_admin" "%CLOUDPASS%" 0
if errorlevel 1 goto FAIL
goto DONE

:RUNSCRIPTS
set RS_SERVER=%~1
set RS_DB=%~2
set RS_USER=%~3
set RS_PASS=%~4
set RS_CAPTURE=%~5

echo Running on %RS_SERVER% / %RS_DB% (InstallCapture=%RS_CAPTURE%) ...

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -i "DataSync_01_Schema.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -i "DataSync_03_ApplyInbound.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -i "DataSync_10_SyncApply_Generic.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -i "DataSync_05_Sales.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -i "DataSync_06_Purchase.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -i "DataSync_11_AllTables_Install.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -v InstallCapture=%RS_CAPTURE% -i "DataSync_11_RunInstall.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -i "DataSync_14_MasterPriority.sql"
if errorlevel 1 exit /b 1

sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -I -b -v InstallCapture=%RS_CAPTURE% -i "DataSync_15_ERPTransactionTables.sql"
if errorlevel 1 exit /b 1

echo.
echo --- Verify %RS_DB% ---
sqlcmd -S "%RS_SERVER%" -d "%RS_DB%" -U "%RS_USER%" -P "%RS_PASS%" -C -Q "SELECT COUNT(*) AS EnabledTables FROM dbo.SyncConfig WHERE IsEnabled=1; SELECT COUNT(*) AS OutboxTriggers FROM sys.triggers WHERE name LIKE 'tr_SyncOutbox_%'; SELECT TOP 15 TableName, Priority, CaptureLocal FROM dbo.SyncConfig WHERE IsEnabled=1 ORDER BY Priority, TableName;"
exit /b 0

:FAIL
echo.
echo DEPLOY FAILED.
pause
exit /b 1

:DONE
echo.
echo All tables sync deploy completed.
echo Rebuild and redeploy SB.SyncAgent if SyncEngine.cs changed.
pause
