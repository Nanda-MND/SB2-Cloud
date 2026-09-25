@echo off
REM Build the recovered SB2 history ListView (Release). Dev PC only.

set MSBUILD=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" (
  set "MSBUILD=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
  set "MSBUILD=%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
)

echo Building SB history ListView...
"%MSBUILD%" "%~dp0SB.csproj" /p:Configuration=Release /p:Platform=AnyCPU /t:Rebuild /v:minimal
if errorlevel 1 (
  echo BUILD FAILED
  exit /b 1
)

echo Built: %~dp0bin\Release\SB.exe
echo ObjectListView hint path: lib\ObjectListView.dll
echo Dev ERP folder, if you copy it: D:\Dev\SB2-Cloud\
echo Do not copy this build to a client PC.
exit /b 0
