# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 (Asia/Rangoon / Myanmar Standard Time UTC+6:30)
HEAD: `0642fa81579866c7cf5a6b32f68c8aee50b25dd1` (`0642fa8`)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Run: FULL transaction sync verification (Tester on Nanda-HP)
Live/Client cutover was not started. SB.exe was not rebuilt/replaced.

## Summary

**OVERALL: BLOCKED at Step 4 (hosting-panel restore)**

Steps 0–3 completed with real evidence. Step 4 cannot use `SB2_Run_TestCloudRestore.ps1` on shared hosting (`RESTORE` / `CREATE DATABASE` permission denied on sql8006). Per `docs/config/SB2_CONNECTIONS.md`, restore of the `.bak` onto `db_abe8c0_sb2` must be done in the hosting panel. Tester has no hosting-panel credentials/automation. Steps 5–6 not run.

## Prerequisites / Step 0

| Check | Result | Evidence |
|-------|--------|----------|
| User-approved discard | PASS | `git checkout --` only tracked dirty under `SB.SyncAgent/bin`, `SB.SyncAgent/obj`, `SB.SyncStatus/obj`. Untracked left alone (`.vs/`, `SB/.vs/`, `_probe_ini/`, `_uia_harness/`). |
| Tracked clean | PASS | `git status` tracked clean after checkout |
| Pull ff-only | PASS | `git fetch`; `git pull --ff-only origin cursor/sb2-dev-test-bootstrap-9fc4` → Already up to date |
| HEAD | PASS | `0642fa81579866c7cf5a6b32f68c8aee50b25dd1` equals required `0642fa8` (exact) |
| Env passwords | PASS | `SB2_DEV_LOCAL_SQL_PASSWORD=SET`, `SB2_TEST_CLOUD_SQL_PASSWORD=SET` (values never printed) |

## Step results

| Step | Result | Evidence |
|------|--------|----------|
| 1 Local bootstrap | PASS | `powershell -File docs\sql\SB2_Run_LocalBootstrap.ps1 -Server localhost -Database SB2 -User sa` exit 0. Tail: `OK Detail Op=D hard delete; Head Op=D soft delete.` / `OK UserRights L2C-only (Local)` / `Dev Local bootstrap finished.` JournalHead/Detail SKIP (not in DB). |
| 2a Fix_AllEntry Local L2C | PASS | `Fix_AllEntry_Local_L2C_Capture.sql` → `DONE ok=41 skip=2 err=0`. AFTER list: all existing Head/Detail `IsEnabled=1 CaptureLocal=1 CaptureCloud=0`. `Still wrong` empty. |
| 2b UserRights Local script | PASS | `DataSync_UserRights_L2C_Only_Local.sql` → `Updated SyncConfig UserRights: CaptureLocal=1, CaptureCloud=0`; row `UserRights 1 1 0` |
| 2c Assert UserRights Local | PASS | `SB2_Assert_UserRights_L2C.sql` `-v Role=Local` → `OK UserRights L2C-only (Local)` exit 0 |
| 3 Backup | PASS | `SB2_Run_Backup.ps1` → `D:\Dev\SB2-Cloud-Runtime\backup\SB2_txn_sync.bak` **Length=146927616** (not committed) |
| 4 Restore Test Cloud | **BLOCKED** | Tried cloud `RESTORE FILELISTONLY FROM DISK = N'D:\Dev\...\SB2_txn_sync.bak'` via `tcp:sql8006.site4now.net,1433` / master → `Msg 262 CREATE DATABASE permission denied` / `RESTORE FILELIST is terminating abnormally`. Doc: hosting-panel restore required. No panel credentials available to Tester. Cloud still reachable: `DB=db_abe8c0_sb2 Server=sql8006 SaleHead=37728` (same SaleHead count as Local; prior parity, **not** a fresh restore of this bak). |
| 5 CloudAfterRestore + reseed + asserts | SKIP | Blocked by Step 4 |
| 5b Cloud_Reseed_TransactionIdRanges | SKIP | Must run on cloud only after restore |
| 5c Fix_AllTxn Cloud C2L | SKIP | |
| 5d–e UserRights cloud + assert | SKIP | |
| 5f Detail hard-delete assert | SKIP | |
| 5g UserStatus ghost cleanup | SKIP | |
| 6 EncryptAndOnce + tray | SKIP | Pending n/a; tray n/a |

## Flags recorded (Local only; Cloud post-restore not run)

| Item | Value |
|------|-------|
| UserRights Local | IsEnabled=1, CaptureLocal=1, CaptureCloud=0 |
| UserStatus Local | IsEnabled=1, CaptureLocal=1, CaptureCloud=0 — **note vs rule "UserStatus not synced / IsEnabled=0"**; not cleared by this run; cloud assert/cleanup skipped |
| Local SaleHead | 37728 |
| Bak path | `D:\Dev\SB2-Cloud-Runtime\backup\SB2_txn_sync.bak` |
| Bak length | 146927616 |
| Bak mtime (Asia/Rangoon) | 2026-09-26 16:38:47 |

## ID-zone / pending / tray

| Check | Result |
|-------|--------|
| Cloud IDENT_CURRENT OK_CLOUD_ZONE | NOT RUN |
| Fix_AllTxn tables IdentCurrent | NOT RUN |
| L2C/C2L Pending after /once | NOT RUN |
| SB.SyncStatus.exe tray | NOT RUN |

## Blockers (action for user/parent)

1. **Hosting-panel restore** of `D:\Dev\SB2-Cloud-Runtime\backup\SB2_txn_sync.bak` (length **146927616**) onto **only** `db_abe8c0_sb2` (sql8006). Do not restore other DBs.
2. After panel restore completes, re-run Tester from **Step 5** through results push (CloudAfterRestore **without** `-EnableTxnC2L`, reseed on cloud only, Fix_AllTxn C2L, UserRights, asserts, ghost cleanup, EncryptAndOnce, tray).
3. Optional follow-up: Local `UserStatus` still CaptureLocal=1 — confirm whether bootstrap should leave it disabled before next full PASS.

## Sign-off

- Steps 0–3: PASS (evidence above).
- Step 4: **BLOCKED** (hosting panel).
- Steps 5–6: SKIP.
- Do **not** mark one-click ready. Do **not** Live/Client cutover.
- Written: 2026-09-26 16:42:34 Asia/Rangoon
