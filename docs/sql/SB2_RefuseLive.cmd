@echo off
echo.
echo SB2 Dev/Test lock: this launcher targets SB1 or the production cloud host.
echo Use the Dev/Test runners instead:
echo   docs\sql\SB2_Run_LocalBootstrap.ps1
echo   docs\sql\SB2_Run_Backup.ps1
echo   docs\sql\SB2_Run_TestCloudRestore.ps1
echo   docs\sql\SB2_Run_CloudAfterRestore.ps1
echo   SB.SyncAgent\SB2_Dev_EncryptAndOnce.ps1
echo SB2 verified pair one-click (localhost/SB2 then sql8006/db_abe8c0_sb2):
echo   docs\sql\SB2_Run_OneClick_Deploy.ps1
echo This launcher still refuses SB1 and SQL1002 / db_abbe78_warehouse.
echo.
exit /b 1
