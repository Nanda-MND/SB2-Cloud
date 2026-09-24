@echo off
REM Cloud sync status check — run on CLIENT PC (Local SQL).
setlocal EnableExtensions
cd /d "%~dp0"

set "SERVER=Server\SB1"
set "DB=SB1"
set "USER=sa"
if "%SQLPASS%"=="" set /p "SQLPASS=Enter Local sa password: "

echo.
echo === 1. Outbox summary ===
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%SQLPASS%" -C -W -s "|" -Q "SELECT Status, COUNT(*) AS Cnt FROM dbo.SyncOutbox WHERE Direction='L2C' GROUP BY Status ORDER BY Status;"

echo.
echo === 2. By table (top 25 pending) ===
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%SQLPASS%" -C -W -s "|" -Q "SELECT TOP 25 TableName, SUM(CASE WHEN Status='Pending' THEN 1 ELSE 0 END) AS Pending, SUM(CASE WHEN Status='Synced' THEN 1 ELSE 0 END) AS Synced, SUM(CASE WHEN Status='DeadLetter' THEN 1 ELSE 0 END) AS DeadLetter FROM dbo.SyncOutbox WHERE Direction='L2C' GROUP BY TableName ORDER BY Pending DESC;"

echo.
echo === 3. Errors (last 10) ===
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%SQLPASS%" -C -W -s "|" -Q "SELECT TOP 10 OutboxID, TableName, Status, AttemptCount, LEFT(LastError,100) AS LastError FROM dbo.SyncOutbox WHERE LastError IS NOT NULL ORDER BY OutboxID DESC;"

echo.
echo === 4. CloudOnline ===
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%SQLPASS%" -C -W -Q "SELECT StateKey, StateValue, UpdatedAt FROM dbo.SyncState WHERE StateKey='CloudOnline';"

echo.
echo === 5. Setting Date (Local) ===
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%SQLPASS%" -C -W -Q "SELECT ID, Date, LogDay, Name FROM dbo.Setting WHERE ID=1;"

echo.
echo === 6. Tables enabled but no outbox yet ===
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%SQLPASS%" -C -W -s "|" -Q "SELECT TOP 20 c.TableName FROM dbo.SyncConfig c WHERE c.IsEnabled=1 AND c.CaptureLocal=1 AND NOT EXISTS (SELECT 1 FROM dbo.SyncOutbox o WHERE o.Direction='L2C' AND o.TableName=c.TableName) ORDER BY c.TableName;"

echo.
echo === 7. Sync done? ===
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%SQLPASS%" -C -W -Q "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.SyncOutbox WHERE Direction='L2C' AND Status IN ('Pending','Syncing')) THEN 'NOT DONE - still draining' ELSE 'DONE - no pending' END AS SyncStatus, (SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Direction='L2C' AND Status='Synced') AS TotalSynced, (SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Direction='L2C' AND Status='DeadLetter') AS DeadLetter;"

pause
