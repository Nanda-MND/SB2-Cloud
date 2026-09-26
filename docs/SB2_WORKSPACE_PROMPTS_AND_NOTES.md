# SB2-Cloud Workspace Prompts, Notes, and Status

Dated: 2026-09-26 Asia/Rangoon (UTC+6:30)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`

## Existing prompt and notes documents

These existing documents are the prompt/note sources already in this repository; they are indexed here rather than duplicating large SQL or implementation text:

- `docs/SB2_Agent_Prompt_Short.md` — concise agent prompt and operating constraints.
- `docs/SB2_PORT_PROMPT.md` — porting prompt and related guidance.
- `docs/SB2_Sync_Bootstrap_Playbook.md` — sync bootstrap/test playbook and status notes.
- `docs/SB2_DEV_TEST_RESULTS.md` — dated development/test results, retained prior PASS sections, and current caveats.
- `docs/SB2_DEV_TEST_RESULTS.template.md` — reusable results template.
- `docs/SB2_AccountCode_Port.md`, `docs/SB2_BankCharges_Port.md`, and `docs/SB2_HistoryListView_Port.md` — porting notes; SQL is not duplicated here.

## Runtime prompt/feedback inventory

Reviewed `D:\Dev\SB2-Cloud-Runtime` for safe prompt, feedback, comment, note, and status text artifacts. No additional clearly named prompt/feedback text file was identified for copying. Secrets, configuration values, INI/BAK files, binaries, and generated build/evidence artifacts are intentionally excluded.

## Known session facts (verbatim)

- Branch `cursor/sb2-dev-test-bootstrap-9fc4`; results commit already at `c71f1ca` with Purchase+Transfer 12/12 E2E markers `E2E_PUR_20260926_223311` / `E2E_XFR_20260926_223311`
- History UI 2a/2c PASS at code `7240060`; MultiSelect must stay OFF; ObjectListView HintPath `..\lib\ObjectListView.dll`
- Suite C read-only spot: SaleHead `45634` FAIL (Cloud Deleted=1 IsDeleted=0); other soft remnants/Purchase/Transfer checks PASS
- Suite A all-txn matrix still IN PROGRESS at evidence `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\all_txn_20260926_225738\` — do NOT invent PASS/FAIL matrix; note IN PROGRESS and point at suiteA_run.log path only
- Do not Live/Client cutover; Dev Local localhost/SB2/sa; Test Cloud sql8006.../db_abe8c0_sb2; passwords from env only (never paste values)
- Soft-delete rules: Detail Op=D hard; Head Op=D soft; UserRights L2C-only; UserStatus not synced

## Current evidence pointers

- Suite C: FAIL only for the stated SaleHead 45634 read-only spot; do not generalize beyond the observed row.
- Suite A: IN PROGRESS; consult `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\all_txn_20260926_225738\suiteA_run.log` only when reviewing live evidence.
- Existing result documents retain earlier PASS sections and are not rewritten here.
