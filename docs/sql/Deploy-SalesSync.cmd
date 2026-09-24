@echo off
REM Enable Sales sync on Local + Cloud. Run from docs\sql folder.

set LOCAL_SERVER=Server\SB1
set LOCAL_DB=SB1
set LOCAL_USER=sa
set /p LOCAL_PASS=Local sa password: 

set CLOUD_SERVER=SQL1002.site4now.net
set CLOUD_DB=db_abbe78_warehouse
set CLOUD_USER=db_abbe78_warehouse_admin
set /p CLOUD_PASS=Cloud password: 

cd /d "%~dp0"

echo.
echo === Local: DataSync_05_Sales.sql ===
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -I -b -i DataSync_05_Sales.sql
if errorlevel 1 goto fail

echo.
echo === Cloud: DataSync_05_Sales.sql ===
sqlcmd -S "%CLOUD_SERVER%" -d "%CLOUD_DB%" -U "%CLOUD_USER%" -P "%CLOUD_PASS%" -C -I -b -i DataSync_05_Sales.sql
if errorlevel 1 goto fail

echo.
echo === Verify ===
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -I -Q "SELECT TableName, IsEnabled, Priority FROM dbo.SyncConfig WHERE TableName IN ('SaleHead','SaleDetail'); SELECT name FROM sys.triggers WHERE name IN ('tr_SyncOutbox_SaleHead','tr_SyncOutbox_SaleDetail');"

echo.
echo Sales sync enabled. Rebuild and copy SB.SyncAgent.exe, then restart service.
echo   net stop SB.SyncAgent
echo   copy new SB.SyncAgent.exe to D:\MinnNandar\Software\
echo   net start SB.SyncAgent
goto end

:fail
echo FAILED
pause
exit /b 1

:end
pause
