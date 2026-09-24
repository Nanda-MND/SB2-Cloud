@echo off
REM Rebuild SB.SyncAgent (Release) — run from repo root or this folder

set MSBUILD=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe
set PROJ=%~dp0SB.SyncAgent.csproj

echo Building Release...
"%MSBUILD%" "%PROJ%" /p:Configuration=Release /p:Platform=AnyCPU /t:Rebuild /v:minimal
if errorlevel 1 (
  echo BUILD FAILED
  pause
  exit /b 1
)

echo.
echo Built: %~dp0bin\Release\SB.SyncAgent.exe
dir "%~dp0bin\Release\SB.SyncAgent.exe"
echo.
echo Copy to ERP folder, then:
echo   net stop SB.SyncAgent
echo   copy /Y bin\Release\SB.SyncAgent.exe D:\MinnNandar\Software\
echo   net start SB.SyncAgent
echo   SB.SyncAgent.exe /test
pause
