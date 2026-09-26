# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 (Asia/Rangoon)  
HEAD: `1a6cc4f1f511c534b9e0dcb7bd8d14ea581509b0` (`1a6cc4f` is ancestor: yes)  
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`  
Environment: Dev PC Tester re-run after `1a6cc4f`. Live/Client cutover was not started.

ALREADY PASS (not re-done): Local bootstrap on `SB2`; hosting-panel restore of post-bootstrap bak onto `db_abe8c0_sb2`.

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 1 | Environment | Only Dev Local + Test Cloud used | PASS | Dev Local `localhost` / `SB2` / `sa`. Test Cloud `sql8006.site4now.net` / `db_abe8c0_sb2`. Forbidden hosts/DBs not used. |
| 2 | Repo | Work done in SB2-Cloud, not live SB | PASS | Branch `cursor/sb2-dev-test-bootstrap-9fc4` at `1a6cc4f1f511c534b9e0dcb7bd8d14ea581509b0`. |
| 3 | Local bootstrap | DataSync + Detail/Head packs + UserRights Local OK | PASS | Already PASS (prior). Local UserRights verify this run: IsEnabled=1 CaptureLocal=1 CaptureCloud=0. |
| 4 | Backup | `SB2_Run_Backup.ps1` exit 0, bak exists Length>0 | PASS | Exit 0. `D:\Dev\SB2-post-fix.bak` Length=143781888. No `InitialCatalog` error; script runner used (not raw sqlcmd BACKUP). |
| 5 | Cloud after-restore | Exit 0 + `OK UserRights L2C-only (TestCloud)` | PASS | `SB2_Run_CloudAfterRestore.ps1` exit 0; output includes `OK UserRights L2C-only (TestCloud)`. Invoked without `-Server tcp:...`. Cloud verify: IsEnabled=1 CaptureLocal=0 CaptureCloud=0; Sync% trigger count=0. |
| 6 | Agent `/once` | Pending near 0; no PurchaseHead connection-closed this cycle | PASS | Defaults: ErpFolder `D:\Dev\SB2-Cloud-Runtime\`, LocalServer localhost, CloudServer sql8006.site4now.net. Ini only under Runtime (not git checkout). `/once` exit 0. After first run L2C Pending=1 (timeout on OutboxID=56); SkipBuild re-run cleared to Pending=0 Synced=194. Post-fix log window (12:00+ Asia/Rangoon) has 0 `current state is closed`; historical 11:15 closed lines remain in append-only log from earlier failed runs. |
| 7 | Master L2C | Dev edit -> Test Cloud | BLOCKED | Not exercised in this post-fix pass (no intentional master edit). |
| 8 | C2L (if enabled) | Test Cloud edit -> Dev | BLOCKED | Not exercised. |
| 9 | Detail delete | Dev delete line -> Test Cloud line gone | BLOCKED | Not exercised. |
| 10 | Head soft-delete | Dev soft-delete -> Test Cloud stays deleted | BLOCKED | Not exercised. |
| 11 | UserRights | Dev change -> Test Cloud; no C2L fight | BLOCKED | Config assert PASS (row 5). End-to-end rights edit not run. |
| 12 | Offline Dev | ERP works; outbox drains later | BLOCKED | Not exercised. |
| 13 | History progress | tspbHistoryLoad shows then hides on fill | BLOCKED | See H1. |
| 14 | History footer | Totals/Paid/PK/Bank Charges correct; Spring keeps totals visible | BLOCKED | See H2/H3. |
| 15 | History MultiSelect | Ctrl/Shift multi-row select stable | BLOCKED | See H4. |
| 16 | History columns | Sales Charges + narrow Car/Discount; cashbook/balance layouts OK | BLOCKED | See H5-H7. |
| 17 | History menu switch | Rapid menu change — no wrong columns / no crash | BLOCKED | See H8. |

## History checks H1–H8

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| H1 | Open Sales history | Progress bar shows then hides; rows bind | BLOCKED | `SB.exe` built and copied to `D:\Dev\SB2-Cloud-Runtime\`; process started (PID probe) then stopped. No GUI driver available to open Sales history and observe progress/bind. Not PASS from code inspection. |
| H2 | Footer | Total / Paid / PK / Bank Charges correct vs data | BLOCKED | Same — interactive UI not driven. |
| H3 | Resize Main | Footer totals still visible (Spring) | BLOCKED | Same. |
| H4 | Multi-select | Ctrl/Shift select multiple rows; UI stable | BLOCKED | Same. |
| H5 | Sales columns | Charges visible; Car/Discount narrow; Amount not crushed | BLOCKED | Same. |
| H6 | Balance menu | Sort/layout OK; Total Closing footer OK | BLOCKED | Same. |
| H7 | Cashbook menu | Cashbook column defaults applied | BLOCKED | Same. |
| H8 | Switch menus rapidly | No wrong columns / no crash / progress ends cleanly | BLOCKED | Same. |

## Sign-off

Post-fix scripts 1–3 (Backup, CloudAfterRestore, EncryptAndOnce) PASS on Dev PC at `1a6cc4f1f511c534b9e0dcb7bd8d14ea581509b0`. H1–H8 remain BLOCKED pending interactive WinForms verification. Live/Client cutover was not opened.

Passwords and `*.ini` / `*.bak` stay out of git. Service `SB.SyncAgent.Dev` was not installed (`-InstallService` not used).

**Next:** Human or GUI-capable agent runs H1–H8 on `D:\Dev\SB2-Cloud-Runtime\SB.exe`. Ask before any Live DB or Client PC cutover.