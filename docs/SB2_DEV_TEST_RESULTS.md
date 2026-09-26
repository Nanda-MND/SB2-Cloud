# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 (Asia/Rangoon / Myanmar Standard Time UTC+6:30)
HEAD: `f23a5488c7a91e6bab4415948503f33dbef5e695` (`f23a548`; parent `856ede6696715e8095d7be12fa6d5d60bec27268`)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Commit under test: f23a548 (history progress UIA + multi-row Edit chrome). Live/Client cutover was not started.

ALREADY PASS at 856ede6 / prior Tester runs (not re-done this run):
- Local bootstrap on `SB2`
- Hosting-panel restore / Backup script / CloudAfterRestore / EncryptAndOnce Pending=0 (prior)
- History **2b** resize footer visibility
- History **2d** Sales columns (Car narrow, Bank Charges visible, Amount not crushed)

Owner correction applied this run: **history list MultiSelect must be OFF** (disabled). 2c judged only against that rule.

## Prerequisites (this run)

| Check | Result | Evidence |
|-------|--------|----------|
| Pull / ancestor | PASS | `git fetch/checkout/pull origin cursor/sb2-dev-test-bootstrap-9fc4`; HEAD exactly `f23a5488c7a91e6bab4415948503f33dbef5e695`; parent 856ede6 |
| HintPath ObjectListView | PASS | `SB\SB.csproj` HintPath `..\lib\ObjectListView.dll` unchanged; `lib\ObjectListView.dll` exists |
| Environment lock | PASS | Dev Local localhost / SB2 only. No sync backup / CloudAfterRestore / EncryptAndOnce re-run. No Live/Client cutover. |

## Build / login

| Step | Result | Evidence |
|------|--------|----------|
| S1 MSBuild Debug AnyCPU Rebuild | PASS | VS2022 Enterprise MSBuild exit 0 after stopping locked SB.exe. No CS0246 / no 777 ObjectListView path. `SB\bin\Debug\SB.exe` Length **1425920** (~1.4MB; not ~31KB stub). |
| Login frm_Login to MinnNandar Solutions | PASS | UIA: first window `frm_Login`; password from env `SB2_DEV_LOCAL_SQL_PASSWORD` via clipboard paste (never printed). `LOGIN_OUTCOME=MAIN_OPEN` / `MAIN_ERP=PASS`. |
| Open Sales then Sales Invoice history | PASS | History list bound (ROW_COUNT=39); footer texts present (PK / Paid / Bank Charges / Total Amount). |

## History checks (corrected 2c)

| # | Test | Expect | Result | Notes |
|---|------|--------|--------|-------|
| 2a | tspbHistoryLoad | UIA ProgressBar Name or AutomationId exactly `tspbHistoryLoad`, visible while binding then hidden | **FAIL** | UIA watcher: `2a_SAW_PROGRESS=False SAW_HIDE=False`. StatusStrip descendants stayed 10 Text-only kids; `pbCount=0`; no element with id/name `tspbHistoryLoad`. Rows binding alone is not PASS. |
| 2b | Resize footer | Total Amount, Paid, PK, Bank Charges stay visible | **PASS** (previous) | Left as PASS from prior run; rebuild/login did not break. |
| 2c | MultiSelect OFF | Runtime `dlvHistory.MultiSelect=false`; Ctrl/Shift must not keep count greater than 1 (selection stays 0 or 1) | **FAIL** | Owner rule: multi-select must be disabled. Runtime UIA: `CanSelectMultiple=True`; Ctrl+click two data rows -> `SEL_AFTER_CTRL=2`; Shift+click third -> `SEL_AFTER_SHIFT=3`. MultiSelect=true with count>1 => FAIL. Edit-disabled-on-multi is not required under this corrected rule. |
| 2d | Sales columns | Charges visible; Car narrow; Discount narrow if present; Amount not crushed | **PASS** (previous) | Left as PASS from prior run; rebuild/login did not break. |

## Sign-off

- Build **PASS** (exe Length 1425920). HintPath OK. HEAD f23a548.
- Login **PASS** (frm_Login to main ERP on localhost/SB2).
- History **2a FAIL** (tspbHistoryLoad not observed via UIA show/hide).
- History **2c FAIL** (MultiSelect is ON at runtime; Ctrl/Shift selects multiple rows -- violates owner OFF requirement).
- History **2b PASS**, **2d PASS** (previous; not invalidated this run).
- Prior bootstrap/backup/cloud/once rows remain PASS (not re-done).
- Live/Client cutover was not opened.
- Passwords and `*.ini` / `*.bak` stay out of git. Harness under `_uia_harness` not committed. Working-tree bin/obj dirt left uncommitted.

**Next:** Turn `dlvHistory.MultiSelect` off (and keep Ctrl/Shift from retaining multi-row selection) for 2c; expose `tspbHistoryLoad` as a real UIA ProgressBar with that exact Name/AutomationId for 2a.