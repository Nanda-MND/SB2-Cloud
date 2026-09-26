# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 (Asia/Rangoon / Myanmar Standard Time UTC+6:30)
HEAD: `7240060c0312646e9da204439232f1684fa3432a` (`7240060`; parent `8f11168`)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Commit under test: 7240060 (Expose history progress to UI Automation and turn multi-select off). Live/Client cutover was not started.

ALREADY PASS at prior Tester runs (not re-done this run unless rebuild broke them):
- Local bootstrap on `SB2`
- Hosting-panel restore / Backup script / CloudAfterRestore / EncryptAndOnce Pending=0 (prior)
- History **2b** resize footer visibility
- History **2d** Sales columns (Car narrow, Bank Charges visible, Amount not crushed)

Owner rule for **2c**: history list MultiSelect must be OFF. Ctrl/Shift must not leave selection count > 1. No Edit-off-for-multi requirement.

## Prerequisites (this run)

| Check | Result | Evidence |
|-------|--------|----------|
| Pull / ancestor | PASS | `git fetch/pull --ff-only origin cursor/sb2-dev-test-bootstrap-9fc4`; `git merge-base --is-ancestor 7240060c0312646e9da204439232f1684fa3432a HEAD` exit 0; HEAD exactly `7240060c0312646e9da204439232f1684fa3432a` |
| HintPath ObjectListView | PASS | `SB\SB.csproj` HintPath `..\lib\ObjectListView.dll` unchanged |
| Environment lock | PASS | Dev Local localhost / SB2 only. No sync backup / CloudAfterRestore / EncryptAndOnce re-run. No Live/Client cutover. Cleared ghost `UserStatus` row so frm_Login could open (stuck "logged on by NANDA-HP" after prior killed SB.exe). |

## Build / login

| Step | Result | Evidence |
|------|--------|----------|
| S1 MSBuild Debug AnyCPU Rebuild | PASS | VS2022 Enterprise MSBuild exit 0. `SB\bin\Debug\SB.exe` Length **1422336** (~1.4MB; not ~31KB stub). |
| Login frm_Login to MinnNandar Solutions | PASS | UIA: first window `frm_Login`; password from env `SB2_DEV_LOCAL_SQL_PASSWORD` via clipboard paste (never printed). `LOGIN_OUTCOME=MAIN_OPEN` / `MAIN_ERP=PASS`. |
| Open Sales then Sales Invoice history | PASS | History list bound (`ROW_COUNT=39`); footer texts present (PK / Paid / Bank Charges / Total Amount). |

## History checks

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 2a | tspbHistoryLoad | Main-window tree: ProgressBar Name or AutomationId exactly `tspbHistoryLoad`, non-zero ~180x18; `SAW_PROGRESS=True` then `SAW_HIDE=True`. Rows alone not PASS. ~600ms hold OK. | **PASS** | Background HWND poller on main window (not StatusStrip-only). Evidence: `2a_PROBE=idOk=True HWND=... vis=True w=180 h=18 id=[tspbHistoryLoad] name=[tspbHistoryLoad]` then `PROGRESS_VISIBLE`; later `vis=False` / `PROGRESS_HIDDEN`. `2a_SAW_PROGRESS=True SAW_HIDE=True SAW_IDENTITY=True`. Native class `msctls_progress32`; UIA ControlType reports `Pane` (custom AccessibleObject) but AutomationId and Name are exactly `tspbHistoryLoad` at 180x18. |
| 2b | Resize footer | Total Amount, Paid, PK, Bank Charges stay visible | **PASS** (previous) | Left as PASS from prior run; rebuild/login did not break. |
| 2c | MultiSelect OFF | Runtime MultiSelect/CanSelectMultiple false; Ctrl/Shift cannot leave count>1; ordinary click selects one | **PASS** | `CanSelectMultiple=False`; `SEL_AFTER_PLAIN0=1`; `SEL_AFTER_CTRL=1`; `SEL_AFTER_SHIFT=1`. `2c_evidence multiProp=False ctrlCount=1 shiftCount=1 plain0=1 OWNER_RULE=MultiSelect_OFF`. Count never reached 2. |
| 2d | Sales columns | Charges visible; Car narrow; Discount narrow if present; Amount not crushed | **PASS** (previous) | Left as PASS from prior run; rebuild/login did not break. |

## Sign-off

- Build **PASS** (exe Length 1422336). HintPath OK. HEAD 7240060.
- Login **PASS** (frm_Login to main ERP on localhost/SB2).
- History **2a PASS** (tspbHistoryLoad show/hide observed via main-window HWND+UIA identity).
- History **2c PASS** (MultiSelect OFF; Ctrl/Shift stay at count 0 or 1).
- History **2b PASS**, **2d PASS** (previous; not invalidated this run).
- Prior bootstrap/backup/cloud/once rows remain PASS (not re-done).
- Live/Client cutover was not opened.
- Passwords and `*.ini` / `*.bak` stay out of git. Harness under `_uia_harness` not committed. Working-tree bin/obj dirt left uncommitted.