/*
  CLOUD ONLY. Run after the Local SB2 .bak is restored onto db_abe8c0_sb2.
  Do not run on localhost / SB2. Do not run on SQL1002, warehouse, erp, luckyone, or SB1.

  Same order as SB2_Run_CloudAfterRestore.ps1 without -EnableTxnC2L
  (the Suite A PASS pack). L2C inserts omit the ID column.
  There is no IDENTITY_INSERT of 2000000000 on Local.

  From docs\sql, SQLCMD mode:
    sqlcmd -S "tcp:sql8006.site4now.net,1433" -d db_abe8c0_sb2 -U db_abe8c0_sb2_admin -C -I -b -i SB2_CloudAfterRestore_Ordered.sql
  Password comes from the sqlcmd -P argument or from the runner, never from this file.

  Prefer: powershell -File docs\sql\SB2_Run_OneClick_Deploy.ps1 -Phase Cloud
*/
:setvar Role TestCloud
:r .\SB2_Assert_NotSB1OrProd.sql
:r .\DataSync_10_SyncApply_Generic.sql
:r .\DataSync_28_EnableC2L_Capture.sql
:r .\Deploy_TxnDetail_HardDeleteSync_CLOUD.sql
:r .\Deploy_EditDeleteSync_CLOUD.sql
:r .\DataSync_UserRights_L2C_Only.sql
:r .\Cloud_Reseed_TransactionIdRanges.sql
:r .\Fix_AllTxn_Cloud_C2L_Capture.sql
:r .\SB2_Repair_HeadSoftDelete_Flags_CLOUD.sql
:r .\SB2_Disable_UserStatus_And_Listview_Sync.sql
:r .\Cloud_UserStatus_GhostCleanup.sql
:r .\Sales_Listview_NarrowCarDiscount.sql
:r .\SB2_Close_RestoredCloud_L2C_Outbox.sql
:r .\SB2_Assert_DetailHardDelete.sql
:r .\SB2_Assert_UserRights_L2C.sql
GO
