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
echo Dev PC only. ERP folder: D:\Dev\SB2-Cloud\
echo Service name: SB2.SyncAgent.Dev
echo Do not copy to a client PC or start SB.SyncAgent.
echo Next: powershell -File SB2_Dev_EncryptAndOnce.ps1
exit /b 0
