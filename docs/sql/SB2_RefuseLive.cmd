@echo off
echo.
echo SB2 Dev/Test lock: this launcher targets SB1 or the production cloud host.
echo Use the Dev/Test runners instead:
echo   docs\sql\SB2_Run_LocalBootstrap.ps1
echo   docs\sql\SB2_Run_Backup.ps1
echo   docs\sql\SB2_Run_TestCloudRestore.ps1
echo   docs\sql\SB2_Run_CloudAfterRestore.ps1
echo   SB.SyncAgent\SB2_Dev_EncryptAndOnce.ps1
echo Live/Client cutover is not approved.
echo.
exit /b 1
