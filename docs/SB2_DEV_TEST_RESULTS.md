# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26  
Environment: Dev PC retest of `cursor/sb2-dev-test-bootstrap-9fc4`, plus this repo update. This Linux workspace still cannot open Dev SQL or the WinForms UI.

Dev PC already passed: Local bootstrap on database `SB2`, hosting-panel restore of that backup onto `db_abe8c0_sb2`, cloud scripts with a manual UserRights trigger drop, and EncryptAndOnce `/once` into a folder that is not a git checkout.

Live/Client cutover was not started. H1–H8 were not run.

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 1 | Environment | Only Dev Local + Test Cloud used | PASS | Dev PC database `SB2` is on the default instance (`localhost`), not a named instance `SB2`. Test Cloud is `sql8006.site4now.net` / `db_abe8c0_sb2`. SQL1002 and `db_abbe78_warehouse` were not used. |
| 2 | Repo | Work done in `SB2-Cloud`, not live SB | PASS | Changes are only in Nanda-MND/SB2-Cloud. SB and SB2 repos were not modified. |
| 3 | Local bootstrap | DataSync + Detail/Head packs + UserRights Local OK | PASS | Dev PC bootstrap on database `SB2` succeeded. `local\SB2` does not resolve (no named instance). Runners now default to `localhost`. Re-run the script with that default when convenient. |
| 4 | Cloud restore | Dev `.bak` restored to Test Cloud | PASS | Hosting panel restored the post-bootstrap `.bak` onto `db_abe8c0_sb2`. `SB2_Run_Backup.ps1` crashed (`InitialCatalog`); that builder path is removed. Re-run the backup script so it writes a `.bak` itself. |
| 5 | Cloud scripts | C2L + Detail/Head CLOUD + UserRights L2C-only | PASS | Cloud scripts ran. UserRights TestCloud assert failed until a manual trigger drop and `CaptureLocal=0`. `DataSync_UserRights_L2C_Only.sql` now drops every UserRights `%Sync%` trigger and sets `CaptureLocal=0`, `CaptureCloud=0`, `IsEnabled=1`. sqlcmd now uses `tcp:sql8006.site4now.net,1433`. Re-run `SB2_Run_CloudAfterRestore.ps1` with no manual TCP prefix and no manual DROP. |
| 6 | Agent `/once` | Dev↔Test Cloud cycle OK | FAIL | EncryptAndOnce `/once` ran in `D:\Dev\SB2-Cloud-Runtime\` (the git checkout `D:\Dev\SB2-Cloud\` is refused). Two runs: Synced 139, Pending 55. Log: PurchaseHead `ExecuteScalar` on a closed connection. Push/pull now re-opens a closed connection and retries that row once. Re-run `/once` and confirm Pending is near 0 with no connection-closed errors. |
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

Dev/Test runtime sign-off is not granted. Rows 4, 5, and 6 still need a clean Dev PC re-run of the fixed backup script, `SB2_Run_CloudAfterRestore.ps1` (TCP, no manual UserRights DROP), and `/once` until Pending is near 0. H1–H8 stay BLOCKED until the Tester runs them.

`Install-SyncStatus.cmd` no longer uses `set /p` inside parentheses. Assert scripts still require bootstrap first, and the runners still pass `sqlcmd -v Role=Local` and `Role=TestCloud`. Passwords and `*.ini` stay out of git.

**Next:** Tester re-check, then H1–H8. Ask before any Live DB or Client PC cutover.
