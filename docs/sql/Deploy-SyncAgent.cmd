@echo off
REM Install Sync Agent on CLIENT PC (Run as Administrator)
REM Place in ERP folder with SB.exe, DBConnection.ini, CloudConnection.ini, SB.SyncAgent.exe

set ERP_DIR=%~dp0
cd /d "%ERP_DIR%"

if not exist "SB.SyncAgent.exe" (
  echo Copy SB.SyncAgent.exe to this folder first.
  pause
  exit /b 1
)
if not exist "DBConnection.ini" (
  echo Missing DBConnection.ini - create with:
  echo   SB.SyncAgent.exe /encrypt DBConnection.ini "Data Source=Server\SB1;..."
  pause
  exit /b 1
)
if not exist "CloudConnection.ini" (
  echo Missing CloudConnection.ini - create with:
  echo   SB.SyncAgent.exe /encrypt CloudConnection.ini "Data Source=SQL1002.site4now.net;..."
  pause
  exit /b 1
)

echo Testing one sync cycle...
SB.SyncAgent.exe /once
if errorlevel 1 (
  echo /once failed - check SyncAgent.log
  pause
  exit /b 1
)

echo Installing Windows Service...
"%WINDIR%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe" /i "SB.SyncAgent.exe"
net start SB.SyncAgent

echo.
echo Sync Agent installed and started.
pause
