@echo off
call "%~dp0SB2_RefuseLive.cmd"
exit /b 1
REM Deploy GetSaleOrderBalSales TVF fix to a SQL Server database.
REM Usage: Deploy-GetSaleOrderBalTVF.cmd
REM   Local: Server\SB1 / SB1
REM   Cloud: SQL1002.site4now.net / db_abbe78_warehouse

setlocal
cd /d "%~dp0"

echo.
echo === Deploy GetSaleOrderBalSales TVF ===
echo.

set /p TARGET=Target [L]ocal Server\SB1 or [C]loud site4now: 
if /i "%TARGET%"=="C" goto CLOUD
goto LOCAL

:LOCAL
set SERVER=Server\SB1
set DB=SB1
set USER=sa
set /p PASS=Enter password: 
goto RUN

:CLOUD
set SERVER=SQL1002.site4now.net
set DB=db_abbe78_warehouse
set USER=db_abbe78_warehouse_admin
set /p PASS=Enter cloud password: 

:RUN
echo.
echo Deploying to %SERVER% / %DB% ...
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%PASS%" -C -I -b -i "GetSaleOrderBalSales_Fix.sql"
if errorlevel 1 (
    echo FAILED.
    pause
    exit /b 1
)

echo.
echo Verify:
sqlcmd -S "%SERVER%" -d "%DB%" -U "%USER%" -P "%PASS%" -C -I -i "Compare-TVF_Versions.sql"
pause
