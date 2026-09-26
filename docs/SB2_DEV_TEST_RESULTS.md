# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 (Asia/Rangoon)
HEAD: `005baafe4ccc6df62a2dc49e0c2c34fc91ac4f7b` (`005baaf`; merge-base --is-ancestor 005baaf HEAD: yes; 4424b69 ancestor: yes)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
ERP copy: `005baaf` WinForms import (`frm_Sales.cs` present). Live/Client cutover was not started.

ALREADY PASS at 4424b69 (not re-done this run):
- Local bootstrap on `SB2`
- Hosting-panel restore of post-bootstrap bak onto `db_abe8c0_sb2`
- Backup script + CloudAfterRestore + EncryptAndOnce Pending=0 (prior Tester run)

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 1 | Environment | Only Dev Local + Test Cloud used | PASS | Dev Local `localhost` / `SB2` / `sa`. Test Cloud `sql8006.site4now.net` / `db_abe8c0_sb2`. Forbidden hosts/DBs not used. |
| 2 | Repo | Work done in SB2-Cloud, not live SB | PASS | Branch `cursor/sb2-dev-test-bootstrap-9fc4` at `005baaf`. Remote `Nanda-MND/SB2-Cloud.git`. |
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
| 13 | History progress | tspbHistoryLoad shows then hides on fill | FAIL | See H1. Source has no `tspbHistoryLoad`; runtime not reachable. |
| 14 | History footer | Totals/Paid/PK/Bank Charges; Spring keeps visible | BLOCKED | See H2/H3. Cannot observe on running new frm_Main (build FAIL). |
| 15 | History MultiSelect | Ctrl/Shift multi-row select stable | FAIL | See H4. Designer sets `dlvHistory.MultiSelect = false`. |
| 16 | History columns | Sales Charges + narrow Car/Discount; Amount not crushed | BLOCKED | See H5. Source has Charges/Car wiring; runtime not reachable. |
| 17 | History menu switch | Rapid menu change — no wrong columns / no crash | BLOCKED | Not run (no exe). |
| S1 | Solution opens / SB builds | `SB.sln` Debug AnyCPU build exit 0; real `SB.exe` >> 31KB stub | FAIL | MSBuild VS2022 Enterprise exit 1. HintPath `..\..\777\777\bin\Debug\ObjectListView.dll` → `D:\Project\777\777\bin\Debug\ObjectListView.dll` missing. MSB3245 Could not resolve ObjectListView. CS0246 BrightIdeasSoftware in frm_Main / frm_Setup / frm_CodeList. Per lock: did NOT copy ObjectListView into repo (not from SB2-git either). After failed Rebuild, `SB\bin\Debug\SB.exe` is absent (prior 31232-byte stub removed by rebuild). |

## Build / login (this run at 005baaf)

| Step | Result | Evidence |
|------|--------|----------|
| Pull / ancestor | PASS | `git pull` up to date; HEAD `005baafe4ccc6df62a2dc49e0c2c34fc91ac4f7b`; `merge-base --is-ancestor 005baaf HEAD` exit 0; `Test-Path SB\frm_Sales.cs` True |
| S1 Build Debug AnyCPU | FAIL | `MSBuild SB.sln /p:Configuration=Debug /p:Platform="Any CPU" /t:Rebuild` exit 1. Primary error: missing ObjectListView at HintPath (see S1 notes). SyncAgent/SyncStatus built; SB project did not. |
| Login frm_Login | BLOCKED | No buildable `SB.exe` from this import. `Program.cs` does `Application.Run(new frm_Login())` in source, but first-window / login UI not observed. Did not write ini into git checkout; did not point at live server. |
| Main ERP after login | BLOCKED | Depends on successful login. |

## History checks (NEW frm_Main only — do not reuse sample-app H1–H8 PASS)

PASS only if observed on new frm_Main after login. This run: build FAIL → no runtime. Source inspected for evidence only.

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| H1 | tspbHistoryLoad | Progress bar shows then hides while history loads | FAIL | `findstr tspb` / `tspbHistoryLoad` across `SB\*.cs`: no matches. No ToolStripProgressBar in `frm_Main.Designer.cs`. Not observed at runtime. |
| H2 | Footer Totals/Paid/PK/Bank Charges | Labels correct vs data | BLOCKED | Source has `ShowTotalAmount`, `tslbMachine` / `tsLabelPaid` / `tsLabelBankCharges` and comment "Keep PK / Paid / Bank Charges / Total Amount visible". Not observed on running UI. |
| H3 | Resize Main / Spring | Footer totals still visible | BLOCKED | Source: `tssLeft.Spring = true` (frm_Main.Designer.cs:206). Not observed after resize on running new frm_Main. |
| H4 | MultiSelect | `dlvHistory.MultiSelect` true; Ctrl/Shift works | FAIL | `frm_Main.Designer.cs:1520`: `this.dlvHistory.MultiSelect = false;` also `SelectAllOnControlA = false`. Runtime multi-select not tested. |
| H5 | Sales columns | Charges visible; Car/Discount narrow; Amount not crushed | BLOCKED | Source: SaleHistory dcol includes Car + Charges; Charges→"Bank Charges" width floor 110; FAmount labeled Amount. `Discount` string not found in frm_Main.cs. Runtime column widths not observed. |
| H6 | Balance menu | Sort/layout OK | BLOCKED | Not run. |
| H7 | Cashbook menu | Cashbook column defaults | BLOCKED | Not run. |
| H8 | Switch menus rapidly | No wrong columns / crash | BLOCKED | Not run. |

## Sign-off

S1 Build **FAIL** (ObjectListView HintPath missing; DLL not copied into repo). Login and history runtime checks **BLOCKED** / **FAIL** as above. Prior bootstrap/backup/cloud/once rows remain PASS from 4424b69 (not re-done). Old sample-app H1–H8 PASS values were **not** carried forward. Live/Client cutover was not opened.

Passwords and `*.ini` / `*.bak` stay out of git. Working tree bin/obj dirt left uncommitted.

**Next:** Agent pointed ObjectListView at `lib\ObjectListView.dll` and wired `tspbHistoryLoad`, the status-strip spring, MultiSelect, and Sales column widths on the imported `frm_Main`. Tester re-runs build, login (`frm_Login`, localhost / SB2), and history 2a–2d. These rows stay FAIL/BLOCKED until that run. Ask before any Live DB or Client PC cutover.