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
- Suite C SaleHead `45634` later PASS (Cloud Deleted=1, IsDeleted=1, DeletedAt set). The 2026-09-26 FAIL spot is historical. See the current summary in `docs/SB2_DEV_TEST_RESULTS.md`.
- Suite A full all-txn matrix OVERALL PASS at results `e3f19a5` (prep `0591d2d`): PASS=122 FAIL=0 SKIP=6, marker `E2E_ALLTXN_20260927_113115`, evidence `all_txn_20260927_112115` (disk only). The 2026-09-26 run remains PASS=113 FAIL=9 SKIP=6 and is not rewritten. Prep order: LocalPendingFix, then CloudAfterRestore with no `-EnableTxnC2L`, then EncryptAndOnce. L2C inserts omit the ID column. No Local IDENTITY_INSERT of 2000000000.
- Do not Live/Client cutover; Dev Local localhost/SB2/sa; Test Cloud sql8006.../db_abe8c0_sb2; passwords from env only (never paste values)
- Soft-delete rules: Detail Op=D hard; Head Op=D soft; UserRights L2C-only; UserStatus not synced

## Current evidence pointers

- Suite C SaleHead 45634: later PASS on Cloud (`IsDeleted=1`, `DeletedAt` set). Do not treat the earlier read-only FAIL as current.
- Suite A current status: full matrix OVERALL PASS (122/0/6) at the top of `docs/SB2_DEV_TEST_RESULTS.md` (results `e3f19a5`). Runnable families there are verified. SKIP families (Journal, Manufacture, Stock meta, CustSupTransfer detail hard-delete, CONFLICT_C4) need tables or paths before a coverage claim. The 113/9/6 log remains at `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\all_txn_20260926_225738\suiteA_run.log`. The passing run is `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\all_txn_20260927_112115\`.
- Existing result documents retain earlier PASS sections and are not rewritten here.
