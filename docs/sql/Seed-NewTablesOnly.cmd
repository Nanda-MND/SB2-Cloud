@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
setlocal EnableExtensions
REM Safe seed — NEW tables only. Skips Sale/Purchase already in outbox.
cd /d "%~dp0"

set "LOCAL_SERVER=Server\SB1"
set "LOCAL_DB=SB1"
set "LOCAL_USER=sa"
set /p "LOCAL_PASS=Enter Local sa password: "

echo.
echo Creating/updating seed procs...
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -I -b -i "DataSync_13_InitialSeed.sql"
if errorlevel 1 goto FAIL

echo.
echo Seeding NEW tables only (batch 200)...
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -Q "EXEC dbo.SyncSeed_NewTablesOnly @BatchSize = 200;"
if errorlevel 1 goto FAIL

echo.
echo Pending by table:
sqlcmd -S "%LOCAL_SERVER%" -d "%LOCAL_DB%" -U "%LOCAL_USER%" -P "%LOCAL_PASS%" -C -W -Q "SELECT TableName, Status, COUNT(*) AS Cnt FROM dbo.SyncOutbox WHERE Direction='L2C' GROUP BY TableName, Status ORDER BY TableName, Status;"
goto DONE

:FAIL
echo FAILED.
pause
exit /b 1

:DONE
pause
