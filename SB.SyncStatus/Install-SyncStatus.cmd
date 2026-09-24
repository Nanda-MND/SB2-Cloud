@echo off
REM Install tray status on LOCAL SERVER PC only (same folder as SB.exe).
REM Do NOT copy this to other client PCs.

setlocal
set SRC=%~dp0bin\Release\SB.SyncStatus.exe
set ERP=D:\MinnNandar\Software

if not exist "%SRC%" (
  echo Build first: Build-SyncStatus.cmd
  pause
  exit /b 1
)

echo.
echo === SB Sync Status — Local Server PC only ===
echo Other client PCs do not need this app.
echo.
if not exist "%ERP%\DBConnection.ini" (
  set /p ERP=ERP folder (must contain DBConnection.ini): 
)

if not exist "%ERP%\DBConnection.ini" (
  echo Missing DBConnection.ini in:
  echo   %ERP%
  echo Put SB.SyncStatus.exe next to SB.exe / DBConnection.ini
  pause
  exit /b 1
)

echo Copy to %ERP%
copy /Y "%SRC%" "%ERP%\SB.SyncStatus.exe" >nul
if exist "%~dp0bin\Release\SB.SyncStatus.exe.config" (
  copy /Y "%~dp0bin\Release\SB.SyncStatus.exe.config" "%ERP%\SB.SyncStatus.exe.config" >nul
)

echo Starting tray app (also registers Windows startup for this user)...
start "" "%ERP%\SB.SyncStatus.exe"

echo.
echo Done. Look for the green / yellow / red dot next to the clock.
echo Left-click: status window
echo Right-click: menu (Start with Windows, Exit)
echo.
pause
exit /b 0
