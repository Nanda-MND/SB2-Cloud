@echo off
REM Run on CLIENT PC after SQL login works.
REM Double-click or: Deploy-LocalSync.cmd

set SERVER=Server\SB1
set DATABASE=SB1
set SQLUSER=sa
set /p SQLPASS=Enter sa password: 

set SCRIPTDIR=%~dp0
cd /d "%SCRIPTDIR%"

echo.
echo === Data Sync deploy: Local %SERVER% / %DATABASE% ===
echo.

for %%F in (
  DataSync_01_Schema.sql
  DataSync_04_SoftDelete_Migration.sql
  DataSync_03_ApplyInbound.sql
  DataSync_02_ChangeCapture_Template.sql
) do (
  echo Running %%F ...
  sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -I -b -i "%%F"
  if errorlevel 1 (
    echo FAILED on %%F
    pause
    exit /b 1
  )
)

echo.
echo === Verify ===
sqlcmd -S "%SERVER%" -d "%DATABASE%" -U "%SQLUSER%" -P "%SQLPASS%" -C -Q "SELECT TableName, IsEnabled, CaptureLocal FROM dbo.SyncConfig WHERE IsEnabled=1; SELECT name FROM sys.triggers WHERE name LIKE 'tr_Sync%%Customer%';"

echo.
echo Local sync SQL completed successfully.
pause
