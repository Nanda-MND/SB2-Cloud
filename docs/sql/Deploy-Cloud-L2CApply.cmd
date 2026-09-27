@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1

REM Cloud L2C apply — full deploy (permissions + SyncApply + wrappers + verify)

REM Run from PC that can reach site4now Cloud SQL.



set SERVER=SQL1002.site4now.net

set DATABASE=db_abbe78_warehouse

set SQLUSER=db_abbe78_warehouse_admin

set /p SQLPASS=Enter cloud SQL password: 



set SCRIPTDIR=%~dp0

cd /d "%SCRIPTDIR%"



set SQLCMD=sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b



echo.

echo === 0. Diagnose (before) ===

%SQLCMD% -i "Diagnose-Cloud-L2C.sql"



echo.

echo === 1. db_owner + IDENTITY_INSERT test ===

%SQLCMD% -i "Fix_Cloud_IdentityInsert.sql"

if errorlevel 1 goto fail



echo.

echo === 2. SyncApply_Generic (IDENTITY_INSERT batch fix) ===

%SQLCMD% -i "DataSync_10_SyncApply_Generic.sql"

if errorlevel 1 goto fail



echo.

echo === 3. Sales apply wrappers ===

%SQLCMD% -i "DataSync_05_Sales.sql"

if errorlevel 1 goto fail



echo.

echo === 4. Purchase apply wrappers ===

%SQLCMD% -i "Fix_Purchase_DeadLetter.sql"

if errorlevel 1 goto fail



echo.

echo === 5. Enable all Cloud inbound tables ===

%SQLCMD% -i "DataSync_21_EnableAllCloudInbound.sql"

if errorlevel 1 goto fail



echo.

echo === 6. Verify ===

%SQLCMD% -i "Verify-SyncApply_Cloud.sql"

if errorlevel 1 goto fail



echo.

echo === 7. Diagnose (after) ===

%SQLCMD% -i "Diagnose-Cloud-L2C.sql"



echo.

echo Cloud L2C deploy OK.

echo Next on LOCAL: Retry-L2C-DeadLetter.sql then SB.SyncAgent.exe /drain 15

pause

exit /b 0



:fail

echo DEPLOY FAILED — check SSMS error above. Run Diagnose-Cloud-L2C.sql on Cloud.

pause

exit /b 1

