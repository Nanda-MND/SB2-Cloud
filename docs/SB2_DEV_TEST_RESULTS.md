# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 (Asia/Rangoon / Myanmar Standard Time UTC+6:30)
HEAD at verification start (Steps 0-3): `0642fa81579866c7cf5a6b32f68c8aee50b25dd1` (`0642fa8`)
Prior results commit (Step 4 BLOCKED): `df3d2a2727467b99b83165a12082498a89913fec` (`df3d2a2`)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Run: FULL transaction sync verification continued after user-confirmed hosting-panel restore
Live/Client cutover was not started. SB.exe was not rebuilt/replaced. History UI not retested.

## Summary

**OVERALL: FAIL** (scripts 5a–g ran; ID-zone Fix_AllTxn-only FAIL; UserStatus still synced; L2C Pending ≠ 0 after /once)

- Steps 0–3: PASS (prior evidence retained)
- Step 4: PASS (user confirmed hosting-panel restore onto `db_abe8c0_sb2`)
- Step 5a–g script execution: PASS (exit 0 / OK asserts)
- Cloud reseed tables: PASS (`OK_CLOUD_ZONE`)
- Fix_AllTxn-only ID zone: **FAIL** (all listed identity tables IdentCurrent < 2000000000)
- UserStatus rule: **FAIL** (Cloud `IsEnabled=1 CaptureLocal=1 CaptureCloud=0`; proc exists)
- Step 6 /once: ran OK but **L2C Pending remain** (FAIL vs Pending=0)
- C2L Pending: **0 PASS**
- Tray: **PASS** (`SB.SyncStatus` running)

## Prerequisites (this continuation)

| Check | Result | Evidence |
|-------|--------|----------|
| Tracked clean | PASS | Only untracked `.vs/`, `SB/.vs/`, `_probe_ini/`, `_uia_harness/` |
| Pull ff-only | PASS | Already up to date at `df3d2a2`; ancestor of `0642fa8` |
| Env passwords | PASS | Both SET (never printed) |
| Step 4 restore | PASS | User confirmed restore onto `db_abe8c0_sb2` only |

## Steps 0–3 (prior; not re-run)

| Step | Result | Evidence |
|------|--------|----------|
| 0 clean+pull | PASS | Discarded SyncAgent/SyncStatus bin/obj; HEAD `0642fa8` |
| 1 Local bootstrap | PASS | Detail hard-delete OK; UserRights L2C Local OK |
| 2 Local L2C + UserRights | PASS | Fix_AllEntry ok=41 skip=2; UserRights `1/1/0`; assert OK Local |
| 3 Backup | PASS | `D:\Dev\SB2-Cloud-Runtime\backup\SB2_txn_sync.bak` Length=**146927616** |

## Step 4

| Step | Result | Evidence |
|------|--------|----------|
| 4 Hosting-panel restore | PASS | User confirmed done onto `db_abe8c0_sb2`. (sqlcmd RESTORE remains permission-denied on shared host; panel path is correct.) |

## Step 5 (CLOUD)

| Step | Result | Evidence |
|------|--------|----------|
| 5a CloudAfterRestore.ps1 (no -EnableTxnC2L) | PASS | Target OK `db_abe8c0_sb2` / `sql8006`. Detail deploy BadCount=0. `OK Detail Op=D hard delete; Head Op=D soft delete.` `OK UserRights L2C-only (TestCloud)`. Finished. Note: EditDelete deploy printed `Fresh C2L PurchaseHead Op=D: 80` (later seen as L2C Pending). |
| 5b Cloud_Reseed_TransactionIdRanges.sql | PASS | All present reseed tables `IDENT_CURRENT=1999999999` `OK_CLOUD_ZONE`. JournalHead/Detail SKIP missing. |
| 5c Fix_AllTxn_Cloud_C2L_Capture.sql | PASS | `DONE ok=41 skip=2 err=0`. AFTER: existing txn `IsEnabled=1 CaptureLocal=0 CaptureCloud=1`. Still wrong empty. |
| 5d DataSync_UserRights_L2C_Only.sql | PASS | UserRights `1/0/0`; no `%Sync%` triggers |
| 5e Assert UserRights Role=TestCloud | PASS | `OK UserRights L2C-only (TestCloud)` |
| 5f Assert DetailHardDelete | PASS | `OK Detail Op=D hard delete; Head Op=D soft delete.` |
| 5g Cloud_UserStatus_GhostCleanup.sql | PASS (script) | `UserStatus_CleanupGhosts deleted rows: 0`. `OBJECT_ID(UserStatus_CleanupGhosts)=1589632756` exists. SQL Agent job not required (SKIP OK). |

### Cloud flags

| Item | Value | Rule |
|------|-------|------|
| UserRights | IsEnabled=1 CaptureLocal=0 CaptureCloud=0; no Sync trigger | PASS |
| UserStatus | IsEnabled=1 CaptureLocal=1 CaptureCloud=0 | **FAIL** (expect IsEnabled=0 or not synced) |
| Existing txn (Fix_AllTxn AFTER) | CaptureCloud=1 CaptureLocal=0 IsEnabled=1 | PASS |

### ID-zone

**Reseed script tables:** all present → `OK_CLOUD_ZONE` (PASS).

**Fix_AllTxn-only (not in reseed) — all ID_ZONE_FAIL:**

| Table | IdentCurrent | Status |
|-------|--------------|--------|
| AccountOpeningDetail | 41 | ID_ZONE_FAIL |
| AccountOpeningHead | 5 | ID_ZONE_FAIL |
| CustomerOpeningDetail | 1138 | ID_ZONE_FAIL |
| CustomerOpeningHead | 4 | ID_ZONE_FAIL |
| CustSupTransfer | 2114 | ID_ZONE_FAIL |
| FinishGoodsDetail | 1439 | ID_ZONE_FAIL |
| FinishGoodsHead | 1112 | ID_ZONE_FAIL |
| GetStockDetail | 1 | ID_ZONE_FAIL |
| GetStockHead | 1 | ID_ZONE_FAIL |
| ManufacturerOpeningDetail | 1 | ID_ZONE_FAIL |
| ManufacturerOpeningHead | 1 | ID_ZONE_FAIL |
| RawIssueDetail | 2109 | ID_ZONE_FAIL |
| RawIssueHead | 2106 | ID_ZONE_FAIL |
| ReturnReceiveDetail | 34 | ID_ZONE_FAIL |
| ReturnReceiveHead | 17 | ID_ZONE_FAIL |
| ReturnStockDetail | 1 | ID_ZONE_FAIL |
| ReturnStockHead | 1 | ID_ZONE_FAIL |
| StockOpeningDetail | 1413 | ID_ZONE_FAIL |
| StockOpeningHead | 38 | ID_ZONE_FAIL |
| SupplierOpeningDetail | 6 | ID_ZONE_FAIL |
| SupplierOpeningHead | 5 | ID_ZONE_FAIL |

Local was not reseeded (correct).

## Step 6

| Step | Result | Evidence |
|------|--------|----------|
| EncryptAndOnce | RAN | `SB2_Dev_EncryptAndOnce.ps1` exit 0. Built Release SyncAgent/SyncStatus; wrote runtime ini; `Sync cycle completed.` / `Dev PC agent step finished.` |
| L2C Pending | **FAIL** | LOCAL L2C Pending=**101**; CLOUD L2C Pending=**135** (not 0) |
| C2L Pending | PASS | LOCAL C2L Pending=0; CLOUD C2L Pending=0 |
| Tray | PASS | `SB.SyncStatus.exe` process running (pid 21004, StartTime 2026-09-26 20:30:13 Asia/Rangoon). No Windows service installed. |

### Pending breakdown (after /once)

**Local Pending:** PurchaseHead D=80; UserStatus U=17; ListViewItem U=4 (total 101 L2C).

**Cloud Pending (top):** PurchaseHead L2C D=80; UserStatus L2C U=24; Users L2C U=20; ListViewItem L2C U=8; plus UserStatus I, UserLoginInfo I, LogInClient U.

### SyncAgent.log (tables named; no conn strings)

Recent /once window flooded with `C2L conflict … PurchaseHead` (OutboxID 326–405 examples: IDs 24…3875). Conflicts align with soft-delete PurchaseHead Op=D rows from Cloud EditDelete deploy / restored outbox — sync did not drain L2C Pending to 0.

## Sign-off

- Do **not** mark one-click ready.
- Do **not** Live/Client cutover.
- Failures to clear before PASS: (1) extend cloud reseed or accept/document Fix_AllTxn-only ID zones; (2) disable UserStatus sync on cloud (and ideally local); (3) clear stuck L2C Pending (PurchaseHead D / UserStatus / Users / ListViewItem) without inventing data fixes.
- Bak Length 146927616 retained under runtime (not in git).
- Written: 2026-09-26 20:33:25 Asia/Rangoon
## Tester recheck (current run, 2026-09-26 Asia/Rangoon)

Owner instruction: fresh restore skipped; current Test Cloud `sql8006 / db_abe8c0_sb2` used. No SB2-git, SB.exe rebuild, service operation, or password output.

### Steps executed

- Step 2 `SB2_Run_LocalPendingFix.ps1 -Server localhost -Database SB2 -User sa`: exit 0. Local UserStatus/ListViewItem sync disabled; UserRights remained `1/1/0`.
- Step 3 `SB2_Run_CloudAfterRestore.ps1` (without `-EnableTxnC2L`): exit 0. Target guard passed; detail hard-delete/head soft-delete and UserRights L2C-only assertions passed. Cloud reseed and capture setup completed; PurchaseHead Op=D requeue was 80.
- Step 4 `SB2_Dev_EncryptAndOnce.ps1`: first attempt was blocked by the optional runtime `SB.SyncStatus.exe` tray process holding the destination. Only that process was stopped (no service); retry exit 0: Release SyncAgent/SyncStatus built, runtime connection files encrypted, and `/once` completed.

### Acceptance checks

**(a) Identity zones: PASS.** All requested Cloud tables are `IDENT_CURRENT=1999999999 / OK_CLOUD_ZONE`: AccountOpeningDetail/Head, CustomerOpeningDetail/Head, CustSupTransfer, FinishGoodsDetail/Head, GetStockDetail/Head, ManufacturerOpeningDetail/Head, RawIssueDetail/Head, ReturnReceiveDetail/Head, ReturnStockDetail/Head, StockOpeningDetail/Head, SupplierOpeningDetail/Head. Local was not reseeded: `SaleHead=45637`, `PurchaseHead=3913`.

**(b) Sync rules: PASS.** Local and Cloud UserStatus are `0/0/0`; UserStatus sync triggers are absent; Cloud `UserStatus_CleanupGhosts` exists (`object_id=1589632756`). UserRights is Local `1/1/0`, Cloud `1/0/0`, with no `%Sync%` triggers. ListViewItem is `0/0/0` on both (where present).

**(c) Script/assertions and soft deletes: PASS.** CloudAfterRestore exit 0; `OK Detail Op=D hard delete; Head Op=D soft delete`; `OK UserRights L2C-only (TestCloud)`; Cloud `PurchaseHead IsDeleted=1` count is `80` (expected approximately 80).

**(d) Pending: PASS.** Read-only checks after `/once` returned no Local or Cloud `Pending`, `Syncing`, or `DeadLetter` groups for either L2C or C2L; therefore no LastError groups to report.

**OVERALL: PASS** (checks a-d all pass).

