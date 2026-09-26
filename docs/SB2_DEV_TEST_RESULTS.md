# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 2026-09-26 14:17:01 (Asia/Rangoon / Myanmar Standard Time UTC+6:30)
HEAD: `deba3081edb2c5fdf78b9aaa29ae06ff407f2506` (`deba308`; merge-base --is-ancestor deba308 HEAD: yes)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Commit under test: deba308 (ObjectListView HintPath + frm_Main history wiring). Live/Client cutover was not started.

ALREADY PASS at 4424b69 (not re-done this run):
- Local bootstrap on `SB2`
- Hosting-panel restore of post-bootstrap bak onto `db_abe8c0_sb2`
- Backup script + CloudAfterRestore + EncryptAndOnce Pending=0 (prior Tester run)

## Prerequisites (this run)

| Check | Result | Evidence |
|-------|--------|----------|
| Pull / ancestor | PASS | `git fetch/checkout/pull origin cursor/sb2-dev-test-bootstrap-9fc4`; HEAD `deba308`; `merge-base --is-ancestor deba308 HEAD` exit 0 |
| HintPath ObjectListView | PASS | `SB\SB.csproj` HintPath `..\lib\ObjectListView.dll`; `lib\ObjectListView.dll` exists (Length 444928) |
| Program.cs entry | PASS | `Application.Run(new frm_Login())` |
| Environment lock | PASS | Dev Local `localhost` / `SB2` / `sa` only for ERP login. Test Cloud passwords unused this run. Forbidden hosts/DBs / service SB.SyncAgent not used. |

## Build / login

| Step | Result | Evidence |
|------|--------|----------|
| S1 MSBuild Debug AnyCPU Rebuild | PASS | VS2022 Enterprise MSBuild exit 0. No error mentioning `D:\Project\777\...\ObjectListView.dll` or CS0246 BrightIdeasSoftware. `SB\bin\Debug\SB.exe` Length **1420800** (>> 31232). |
| First window frm_Login | PASS | UIA: first main window title `frm_Login`; `tbPassword` / `btLogin` present. |
| Login localhost/SB2 | PASS | Env password via UI Automation clipboard paste (never printed). Main ERP title `MinnNandar Solutions` opened. Dev Local `DBConnection.ini` decrypts to DataSource=`(local)` InitialCatalog=`SB2` UserID=`sa`. |
| Main ERP after login | PASS | UIA `LOGIN_OUTCOME=MAIN_OPEN` / `MAIN_ERP=PASS`. |

Notes for login setup on Dev Local only (not committed): machine `NANDA-HP` was missing from `LogInClient` (would show Unregistered Computer Name); inserted LoginClient + UserLoginInfo for Administrator; Administrator app password aligned to `SB2_DEV_LOCAL_SQL_PASSWORD` via app RC4 Encrypt for CheckPassword. No live-server ini written into git.

## History checks (NEW frm_Main only — do not reuse sample-app H1–H8)

Opened **Sales → Sales Invoice** on running new `frm_Main` after login. History list bound (41 UIA child rows; footer Total Amount 20,068,696).

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 2a | tspbHistoryLoad | Progress bar shows then hides on bind | FAIL | UIA watcher during Sales Invoice click: `2a_SAW_PROGRESS=False SAW_HIDE=False`. Bind succeeded (rows + footer appeared) but ToolStripProgressBar was not observed as a visible ProgressBar in the UIA tree (likely too brief and/or StatusStrip-hosted bar not exposed). Source does call `BeginHistoryLoadProgress` / `EndHistoryLoadProgress`. Failed-load provocation not run. |
| 2b | Resize footer | Total Amount, Paid, PK, Bank Charges stay visible | PASS | After maximize/restore: status texts included `PK : 15`, `Paid Amount : 0`, `Bank Charges : 0`, `Total Amount : 20,068,696`. |
| 2c | MultiSelect / Edit / Delete / Print | MultiSelect true; Ctrl/Shift multi; Edit disabled when >1; Delete+Print enabled | FAIL | Designer + `EnsureHistoryChrome` set `dlvHistory.MultiSelect = true` (confirmed). Runtime: list found, 41 rows; Ctrl+click attempted; context menu showed **Edit enabled=True** and **Print enabled=True** — Edit did not disable, so multi-row selection was not confirmed via UIA. Delete enablement not confirmed on menu. |
| 2d | Sales columns | Charges visible; Car narrow; Discount narrow if present; Amount not crushed | PASS | Headers: `Car:w=39`; `Bank Charges:w=90`; `Amount:w=129`; Discount column absent (OK). |

## Sign-off

- Build **PASS** (exe Length 1420800). HintPath OK. deba308 ancestor OK.
- Login **PASS** (frm_Login → main ERP on localhost/SB2).
- History 2b **PASS**, 2d **PASS**; 2a **FAIL** (progress not observed); 2c **FAIL** (multi-select Edit-disable not confirmed at runtime).
- Prior bootstrap/backup/cloud/once rows remain PASS from 4424b69 (not re-done).
- Live/Client cutover was not opened.
- Passwords and `*.ini` / `*.bak` stay out of git. Harness under `_uia_harness` / `_probe_ini` not committed. Working-tree bin/obj dirt left uncommitted.

**Next:** Investigate ToolStripProgressBar UIA visibility / longer show for 2a; drive genuine multi-row selection on ObjectListView so Edit disables for 2c. Ask before any Live DB or Client PC cutover.