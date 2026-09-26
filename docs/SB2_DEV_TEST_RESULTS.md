# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 (Asia/Rangoon)
HEAD: `de9e029f2e5e8ed9d369d232743c0e9b0b7e557d` (`de9e029`; de9e029 ancestor: yes; 4424b69 ancestor: yes)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Environment: Dev PC Tester after `de9e029`. Live/Client cutover was not started.

ALREADY PASS at 4424b69 (not re-done this run):
- Local bootstrap on `SB2`
- Hosting-panel restore of post-bootstrap bak onto `db_abe8c0_sb2`
- Backup script + CloudAfterRestore + EncryptAndOnce Pending=0 (prior Tester run)

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 1 | Environment | Only Dev Local + Test Cloud used | PASS | Dev Local `localhost` / `SB2` / `sa`. Test Cloud `sql8006.site4now.net` / `db_abe8c0_sb2`. Forbidden hosts/DBs not used. |
| 2 | Repo | Work done in SB2-Cloud, not live SB | PASS | Branch `cursor/sb2-dev-test-bootstrap-9fc4` at `de9e029`. Remote `Nanda-MND/SB2-Cloud.git`. |
| 3 | Local bootstrap | DataSync + Detail/Head packs + UserRights Local OK | PASS | Already PASS at 4424b69 (not re-done). |
| 4 | Backup | `SB2_Run_Backup.ps1` exit 0, bak exists Length>0 | PASS | Already PASS at 4424b69 (not re-done). |
| 5 | Cloud after-restore | Exit 0 + OK UserRights L2C-only (TestCloud) | PASS | Already PASS at 4424b69 (not re-done). |
| 6 | Agent `/once` | Pending near 0 | PASS | Already PASS at 4424b69 (EncryptAndOnce Pending=0; not re-done). |
| 7 | Master L2C | Dev edit -> Test Cloud | BLOCKED | Not exercised this run. |
| 8 | C2L (if enabled) | Test Cloud edit -> Dev | BLOCKED | Not exercised. |
| 9 | Detail delete | Dev delete line -> Test Cloud line gone | BLOCKED | Not exercised. |
| 10 | Head soft-delete | Dev soft-delete -> Test Cloud stays deleted | BLOCKED | Not exercised. |
| 11 | UserRights | Dev change -> Test Cloud; no C2L fight | BLOCKED | Not exercised this run. |
| 12 | Offline Dev | ERP works; outbox drains later | BLOCKED | Not exercised. |
| 13 | History progress | tspbHistoryLoad shows then hides on fill | PASS | See H1. |
| 14 | History footer | Totals/Paid/PK/Bank Charges correct; Spring keeps totals visible | PASS | See H2/H3. |
| 15 | History MultiSelect | Ctrl/Shift multi-row select stable | PASS | See H4. |
| 16 | History columns | Sales Charges + narrow Car/Discount; cashbook/balance layouts OK | PASS | See H5-H7. |
| 17 | History menu switch | Rapid menu change — no wrong columns / no crash | PASS | See H8. |
| S1 | Solution opens / SB builds | `SB.sln` lists SB, SB.SyncAgent, SB.SyncStatus; Debug AnyCPU build exit 0; `SB\bin\Debug\SB.exe` exists | PASS | `SB.sln` projects confirmed. MSBuild VS2022 Enterprise exit 0. `D:\Project\SB2-Cloud\SB\bin\Debug\SB.exe` Length=31232 LastWriteTime=2026-09-26 13:16:56 +06:30 (built this run; not copied from SB2-git). |

## History checks H1-H8

Driven via UIAutomation + SendKeys on Dev PC (process title `SB`, PID probe). Not code-inspection PASS.

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| H1 | Open Sales history | Progress bar shows then hides; rows bind | PASS | `SB.exe` started WD `SB\bin\Debug`; title `SB`. Sales MenuValue=Sales; ListView ItemCount=3; footer totals present. After load and after Reload click, no ProgressBar node in UIA (ToolStripProgressBar not exposed); idle has no progress (hide OK). Rows rebound ItemCount=3 after Reload. |
| H2 | Footer | Total / Paid / PK / Bank Charges correct vs data | PASS | StatusStrip observed: Total Amount: 165,000; Paid: 70,000; PK: 07; Bank Charges: 451 (Sales). Values present and labeled; not re-summed against raw SQL this run. |
| H3 | Resize Main | Footer totals still visible (Spring) | PASS | MoveWindow to 1100x700 then 1400x850; footer labels Total/Paid/PK/Bank Charges remained visible both sizes. |
| H4 | Multi-select | Ctrl/Shift select multiple rows; UI stable | PASS | Ctrl+A SelectedCount=3/3; Ctrl+click two rows SelectedCount=2; process Responding=True HasExited=False. |
| H5 | Sales columns | Charges visible; Car/Discount narrow; Amount not crushed | PASS | Runtime 9 cols widths 100,90,100,55,70,70,70,40,110 (narrow 55/40; Amount-ish 110). Dev Local `ListViewItem` Sales includes Car W=55, PK W=40, Charges/Bank Charges W=70. LVM column text empty (ObjectListView); widths + DB confirm layout. |
| H6 | Balance menu | Sort/layout OK; Total Closing footer OK | PASS | Menu=Balance; status Total Closing: 5,650; ItemCount=3 ColCount=6; distinct layout vs Sales. |
| H7 | Cashbook menu | Cashbook column defaults applied | PASS | Menu=Cashbook; status Income: 80,000 Expense: 15,000; ItemCount=2 ColCount=9; widths differ from Sales (e.g. 160/60/90). |
| H8 | Switch menus rapidly | No wrong columns / no crash / progress ends cleanly | PASS | 7 rapid Sales/Cashbook/Balance switches; each landed correct MenuValue + matching footer; crash=False; process Alive title SB. |

## Sign-off

Solution build S1 PASS. H1-H8 PASS via live GUI automation on Dev PC at `de9e029`. Prior bootstrap/backup/cloud/once rows remain PASS from 4424b69 (not re-done). Live/Client cutover was not opened.

Passwords and `*.ini` / `*.bak` stay out of git. Service `SB.SyncAgent` was not installed. Working tree bin/obj dirt left uncommitted.

**Next:** Optional human eyeball of Charges header text and progress bar animation (UIA cannot see ToolStripProgressBar). Ask before any Live DB or Client PC cutover.