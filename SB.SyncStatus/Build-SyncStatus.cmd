@echo off
REM Rebuild SB.SyncStatus (Release)

set MSBUILD=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" (
  set "MSBUILD=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
)
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe" (
  set "MSBUILD=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"
)
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
  set "MSBUILD=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)

set PROJ=%~dp0SB.SyncStatus.csproj

echo Building Release...
"%MSBUILD%" "%PROJ%" /p:Configuration=Release /p:Platform=AnyCPU /t:Rebuild /v:minimal
if errorlevel 1 (
  echo BUILD FAILED
  exit /b 1
)

echo.
echo Built: %~dp0bin\Release\SB.SyncStatus.exe
dir "%~dp0bin\Release\SB.SyncStatus.exe"
echo.
echo Next: run Install-SyncStatus.cmd on the Local Server PC only.
exit /b 0
