# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-25  
Environment: this cloud agent workspace (Linux). It cannot open Dev PC SQL Server, Test Cloud SQL, or the WinForms history UI.

Rule used: rows that need Dev SQL, Test Cloud, or the Dev PC app are **BLOCKED**. They are not marked PASS.

Live/Client cutover was not started.

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 1 | Environment | Only Dev Local + Test Cloud used | BLOCKED | Connection file has DEV/TEST placeholders only. No SQL host was contacted, so this row was not executed. Runners refuse SB1 and `SQL1002.site4now.net`. |
| 2 | Repo | Work done in `SB2-Cloud`, not live SB | PASS | Changes are only in Nanda-MND/SB2-Cloud. SB and SB2 repos were not modified. |
| 3 | Local bootstrap | DataSync + Detail/Head packs + UserRights Local OK | BLOCKED | `SB2_Run_LocalBootstrap.ps1` is in the repo. Dev SQL `YOUR_DEV_PC\INSTANCE` / `SB2` is not reachable from this environment. |
| 4 | Cloud restore | Dev `.bak` restored to Test Cloud | BLOCKED | `SB2_Run_Backup.ps1` and `SB2_Run_TestCloudRestore.ps1` are in the repo. No backup was taken and Test Cloud was not contacted. |
| 5 | Cloud scripts | C2L + Detail/Head CLOUD + UserRights L2C-only | BLOCKED | `SB2_Run_CloudAfterRestore.ps1` is in the repo. It was not executed. |
| 6 | Agent `/once` | Dev↔Test Cloud cycle OK | BLOCKED | `SB2_Dev_EncryptAndOnce.ps1` encrypts Dev/Test ini and runs `/once` on the Dev PC. This environment cannot build the .NET Framework agent or open either SQL host. Ini files were not written and were not committed. |
| 7 | Master L2C | Dev edit → Test Cloud | BLOCKED | Needs a running Dev↔Test sync cycle. |
| 8 | C2L (if enabled) | Test Cloud edit → Dev | BLOCKED | Needs Test Cloud. |
| 9 | Detail delete | Dev delete line → Test Cloud line gone | BLOCKED | Detail Op=D hard-delete marker is in `DataSync_10_SyncApply_Generic.sql` (`hardDeleteDetail`). Runtime delete was not executed. |
| 10 | Head soft-delete | Dev soft-delete → Test Cloud stays deleted | BLOCKED | Head soft-delete marker `preserve-soft-delete-flags` is in `SyncApply_Generic`. Runtime check was not executed. |
| 11 | UserRights | Dev change → Test Cloud; no C2L fight | BLOCKED | Runners assert L2C-only (`CaptureCloud=0`). Not executed against SQL. |
| 12 | Offline Dev | ERP works; outbox drains later | BLOCKED | Needs the Dev PC ERP session. |
| 13 | History progress | tspbHistoryLoad shows then hides on fill | BLOCKED | UI port is in `SB/frm_Main`. Not run on the Dev PC. |
| 14 | History footer | Totals/Paid/PK/Bank Charges correct; Spring keeps totals visible | BLOCKED | Footer labels and `tsslSpring` are on the status strip. Not run on the Dev PC. |
| 15 | History MultiSelect | Ctrl/Shift multi-row select stable | BLOCKED | `dlvHistory.MultiSelect = true`. Not run on the Dev PC. |
| 16 | History columns | Sales Charges + narrow Car/Discount; cashbook/balance layouts OK | BLOCKED | Widths are applied in `FastListViewHelper` and `Sales_Listview_NarrowCarDiscount.sql`. SQL was not run. |
| 17 | History menu switch | Rapid menu change — no wrong columns / no crash | BLOCKED | Generation guard is in `PrepareForLayoutChange`. Not run on the Dev PC. |

## History checks H1–H8

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| H1 | Open Sales history | Progress bar shows then hides; rows bind | BLOCKED | Dev PC WinForms app was not started here. |
| H2 | Footer | Total / Paid / PK / Bank Charges correct vs data | BLOCKED | Same as row 14. |
| H3 | Resize Main | Footer totals still visible (Spring) | BLOCKED | `tsslSpring.Spring = true`. Not resized on a Dev PC display. |
| H4 | Multi-select | Ctrl/Shift select multiple rows; UI stable | BLOCKED | Same as row 15. |
| H5 | Sales columns | Charges visible; Car/Discount narrow; Amount not crushed | BLOCKED | Same as row 16. |
| H6 | Balance menu | Sort/layout OK; Total Closing footer OK | BLOCKED | `SortBalanceTable` + `ApplyBalanceListDefaults`. Not run. |
| H7 | Cashbook menu | Cashbook column defaults applied | BLOCKED | `ApplyCashbookListDefaults`. Not run. |
| H8 | Switch menus rapidly | No wrong columns / no crash / progress ends cleanly | BLOCKED | Same as row 17. |

## What was recovered without the SB reference clone

`FastListViewHelper.cs` was not in this repository, and Nanda-MND/SB was not available to copy from. The helper, `frm_Main` history surface, and `frm_List` were recovered to the API in `docs/SB2_HistoryListView_Port.md`. `lib/ObjectListView.dll` is referenced by `SB/SB.csproj`.

SyncAgent and SyncStatus stay on the existing .NET Framework projects. The Dev service name is `SB2.SyncAgent.Dev`. `/encrypt` and connection open refuse SB1 and the production cloud host.

## Sign-off

Dev/Test runtime sign-off is not granted. BLOCKED rows must be run on the Dev PC against Dev Local and Test Cloud before any Live/Client cutover plan.

Follow-up after Dev PC build `d90aa3e`: `Install-SyncStatus.cmd` no longer uses `set /p` inside parentheses, so cmd.exe does not stop with `: was unexpected at this time.` Assert scripts now say to run `SB2_Run_LocalBootstrap.ps1` first when `SyncConfig` is missing. Runners still pass `sqlcmd -v Role=Local` and `Role=TestCloud`. Connection placeholders, encrypted ini, bootstrap, Test Cloud, and H1-H8 stay BLOCKED until the Dev PC supplies runtime passwords outside git.

**Next:** ask before any Live DB or Client PC cutover document or deploy.
