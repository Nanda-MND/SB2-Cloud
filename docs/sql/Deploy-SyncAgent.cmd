@echo off
REM SB2-Cloud Dev/Test lock.
REM Live/client SyncAgent install is out of scope until a separate cutover is approved.
echo.
echo Refusing live/client SyncAgent install.
echo This phase allows Dev PC only:
echo   ERP folder   D:\Dev\SB2-Cloud\
echo   Service name SB2.SyncAgent.Dev
echo   Script       SB.SyncAgent\SB2_Dev_EncryptAndOnce.ps1
echo.
echo Do not install against SQL1002.site4now.net, db_abbe78_warehouse, or SB1.
exit /b 1
