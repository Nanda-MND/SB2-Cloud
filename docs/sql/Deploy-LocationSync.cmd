@echo off
REM Enable Location sync on Local + Cloud.

set LOCAL_SERVER=Server\SB1
set LOCAL_DB=SB1
set LOCAL_USER=sa
set /p LOCAL_PASS=Local sa password: 

set CLOUD_SERVER=SQL1002.site4now.net
set CLOUD_DB=db_abbe78_warehouse
set CLOUD_USER=db_abbe78_warehouse_admin
set /p CLOUD_PASS=Cloud password: 

cd /d "%~dp0"

echo === Local: DataSync_07_Location.sql ===
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -I -b -i DataSync_07_Location.sql
if errorlevel 1 goto fail

echo === Cloud: DataSync_07_Location.sql ===
sqlcmd -S "%CLOUD_SERVER%" -d "%CLOUD_DB%" -U "%CLOUD_USER%" -P "%CLOUD_PASS%" -C -I -b -i DataSync_07_Location.sql
if errorlevel 1 goto fail

echo === Verify ===
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -I -Q "SELECT TableName, IsEnabled, Priority FROM dbo.SyncConfig WHERE TableName = 'Location'; SELECT name FROM sys.triggers WHERE name = 'tr_SyncOutbox_Location';"

echo Location sync enabled.
goto end
:fail
echo FAILED
pause
exit /b 1
:end
pause
