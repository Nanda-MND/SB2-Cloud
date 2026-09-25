@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM Monitor Local sync progress. Run on client PC.
setlocal

set SERVER=Server\SB1
set DATABASE=SB1
set SQLUSER=sa
if "%SQLPASS%"=="" set /p SQLPASS=Enter Local sa password: 

echo.
echo === Sync Progress ===
echo.

sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -W -s "|" -Q ^
"SELECT TableName, Status, COUNT(*) AS Cnt FROM dbo.SyncOutbox WHERE Direction='L2C' GROUP BY TableName, Status ORDER BY TableName, Status;"

echo.
echo --- Errors (last 10) ---
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -W -s "|" -Q ^
"SELECT TOP 10 OutboxID, TableName, Status, AttemptCount, LEFT(LastError,120) AS LastError FROM dbo.SyncOutbox WHERE LastError IS NOT NULL ORDER BY OutboxID DESC;"

echo.
echo --- Totals ---
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -W -Q ^
"SELECT Status, COUNT(*) AS Cnt FROM dbo.SyncOutbox WHERE Direction='L2C' GROUP BY Status ORDER BY Status;"

echo.
echo --- CloudOnline ---
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -W -Q ^
"SELECT StateKey, StateValue, UpdatedAt FROM dbo.SyncState WHERE StateKey='CloudOnline';"

if not defined NO_PAUSE pause
