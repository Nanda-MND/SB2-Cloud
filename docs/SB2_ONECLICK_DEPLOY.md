# SB2 one-click deploy

Verified pair only. Suite A full matrix PASS (122/0/6) at `e3f19a5`.

| Side | Target |
|------|--------|
| Local | `localhost` / `SB2` / `sa` |
| Cloud | `tcp:sql8006.site4now.net,1433` / `db_abe8c0_sb2` |

Still refused: `SQL1002`, `db_abbe78_warehouse`, `db_abe8c0_erp`, `db_abe8c0_luckyone`, `SB1`, Client PC folder `D:\MinnNandar\Software`, Windows service `SB.SyncAgent`. This does not rebuild `SB.exe`. Passwords stay in `SB2_DEV_LOCAL_SQL_PASSWORD` and `SB2_TEST_CLOUD_SQL_PASSWORD`.

L2C inserts omit the ID column. Do not `IDENTITY_INSERT` `2000000000` on Local.

## မြန်မာ — လုပ်ရမည့်အစီအစဉ်

1. Local DB ကို အရင်ပြင်ပါ (`LocalPendingFix`). ပထမဆုံးအကြိမ်ဆို `-IncludeBootstrap` ထည့်ပါ။
2. Local ကို `COPY_ONLY` backup လုပ်ပါ။ ဒီ `.bak` ထဲက identity က Local တန်ဖိုးပဲ ကျန်သေးတယ်။
3. Hosting panel မှာ အဲဒီ `.bak` ကို Cloud database `db_abe8c0_sb2` အဖြစ် restore လုပ်ပါ။ Shared hosting က ဒီ script ကနေ `RESTORE` လက်မခံပါ။
4. Restore ပြီးမှ အောက်က Cloud SQL ကို အစဉ်လိုက် run ပါ။ `Cloud_Reseed_TransactionIdRanges.sql` ကို ကျော်ရင် Cloud ID က `1999999999` ပြန်ဖြစ်နိုင်တယ်။ Cloud next က `>= 2000000000` ဖြစ်ရမယ်။
5. Dev PC မှာ `SB.SyncAgent\SB2_Dev_EncryptAndOnce.ps1` ကို run ပါ။ Client PC folder ထဲ မကူးပါနဲ့။

```text
powershell -File docs\sql\SB2_Run_OneClick_Deploy.ps1 -Phase Local -BackupPath D:\Dev\SB2-Cloud-Runtime\SB2_copyonly.bak
powershell -File docs\sql\SB2_Run_OneClick_Deploy.ps1 -Phase Cloud
```

SQL host က `RESTORE` ခွင့်ပြုမှသာ `-Phase All -RestoreOnCloud -DataFolder ... -LogFolder ... -AllowReplace` ကို သုံးပါ။

## Local SQL before the backup

`SB2_Run_LocalPendingFix.ps1` (inside the `.bak`):

1. `DataSync_11_AllTables_Install.sql` — L2C triggers. Head `Deleted=1` enqueues Op=D and sets `IsDeleted=1`.
2. `Fix_AllEntry_Local_L2C_Capture.sql` — Local entry capture.
3. `DataSync_10_SyncApply_Generic.sql` — Head Op=D soft, Detail Op=D hard. After C2L, Local identity pulls below `1999999999`.
4. `SB2_Reseed_LocalIdentity_BelowCloudFloor.sql` — Local seed is `MAX(ID)` where `ID < 1999999999`. Aborts if ReturnStock/GetStock stay at the sentinel.
5. `SB2_Disable_UserStatus_And_Listview_Sync.sql` — UserStatus and ListviewItem sync off.

`-IncludeBootstrap` runs `SB2_Run_LocalBootstrap.ps1` first.

## Cloud SQL after restore

File: `docs/sql/SB2_CloudAfterRestore_Ordered.sql`  
Runner: `docs/sql/SB2_Run_CloudAfterRestore.ps1` with no `-EnableTxnC2L`.

Run this pack only on `db_abe8c0_sb2`. Do not run it on Local.

| # | Script | Why |
|---|--------|-----|
| 1 | `SB2_Assert_NotSB1OrProd.sql` | Stop if the catalog is SB1, SQL1002, warehouse, erp, or luckyone. |
| 2 | `DataSync_10_SyncApply_Generic.sql` | Apply procedure. Head Op=D stays soft. Detail Op=D stays a hard delete. |
| 3 | `DataSync_28_EnableC2L_Capture.sql` | Cloud capture for C2L. Head soft-delete sets `IsDeleted=1` and `DeletedAt`. |
| 4 | `Deploy_TxnDetail_HardDeleteSync_CLOUD.sql` | Detail delete on Cloud is a physical delete and Op=D. |
| 5 | `Deploy_EditDeleteSync_CLOUD.sql` | Cloud edit/delete capture. |
| 6 | `DataSync_UserRights_L2C_Only.sql` | UserRights stays L2C-only. Cloud `CaptureCloud=0`. |
| 7 | `Cloud_Reseed_TransactionIdRanges.sql` | Cloud next ID `>= 2000000000`. Never-generated tables reseed to the floor, not `1999999999`. |
| 8 | `Fix_AllTxn_Cloud_C2L_Capture.sql` | Transaction families: Cloud `CaptureCloud=1`, `CaptureLocal=0`. |
| 9 | `SB2_Repair_HeadSoftDelete_Flags_CLOUD.sql` | Older heads with `Deleted=1` and `IsDeleted=0` (SaleHead 45634) get `IsDeleted=1` and `DeletedAt`. No outbox queue. |
| 10 | `SB2_Disable_UserStatus_And_Listview_Sync.sql` | UserStatus and ListviewItem stay off on Cloud too. |
| 11 | `Cloud_UserStatus_GhostCleanup.sql` | Cloud ghost cleanup procedure after the disable. |
| 12 | `Sales_Listview_NarrowCarDiscount.sql` | Sales listview column widths. |
| 13 | `SB2_Close_RestoredCloud_L2C_Outbox.sql` | Close the restored `Direction=L2C` outbox copy. C2L rows stay. |
| 14 | `SB2_Assert_DetailHardDelete.sql` | Detail Op=D is a hard delete. Head Op=D is soft. |
| 15 | `SB2_Assert_UserRights_L2C.sql` | `Role=TestCloud`. UserRights L2C-only. |

`-EnableTxnC2L` adds `DataSync_32_EnableC2L_Sale.sql`, `DataSync_35_EnableC2L_Transfer.sql`, and `DataSync_36_EnableC2L_Purchase.sql`, then asserts UserRights again. The Suite A PASS run did not use that switch. The ordered `.sql` file does not include those three files.

## Not in this one-click

- Journal / Manufacture / Stock meta, and CustSupTransfer detail hard-delete: those tables are absent (Suite A SKIP).
- Copying `SB.exe` or the agent onto a Client PC.
- Production host `SQL1002` and catalog `db_abbe78_warehouse`. The old `Run-ClientSyncDeploy.ps1` still exits through `SB2_RefuseLive.cmd`.
