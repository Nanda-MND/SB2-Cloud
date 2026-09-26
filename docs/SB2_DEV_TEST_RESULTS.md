# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 22:15 Asia/Rangoon (UTC+6:30)
HEAD: `4f35d2e9402974ff20bc85bf615b422e0a73e03c` (`4f35d2e`)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Run: Tester recheck after soft-delete Op=D + detail hard-delete Applied-as-success fix
Machine: Nanda-HP (`e921257a-2870-4ad6-9b01-cfd6b497ecc4`)
Runtime: `D:\Dev\SB2-Cloud-Runtime\`
Targets: Local `localhost` / `SB2` (sa); Cloud `sql8006.site4now.net` / `db_abe8c0_sb2`
Marker: `DISP_20260926_221203`
No fresh bak restore. No SB.exe rebuild. No Windows service. No SB2-git. Passwords from env only (never printed).

## Summary

**OVERALL: PASS**

| Check | Result |
|-------|--------|
| Pull ff-only to `4f35d2e` (descendant of `4debcfb`/`1dfdf7b`) | PASS |
| `SB2_Run_LocalPendingFix.ps1` | PASS (exit 0) |
| `SB2_Run_CloudAfterRestore.ps1` (no `-EnableTxnC2L`) | PASS (exit 0) |
| `SB2_Dev_EncryptAndOnce.ps1` (new SyncAgent deployed + `/once`) | PASS |
| Cloud OutboxID 493 SaleDetail 91986 not Pending after `/once` | PASS (Status=`Synced`) |
| Local+Cloud L2C Pending=0 and C2L Pending=0 | PASS |
| New Local SaleHead soft-delete Op=D + source IsDeleted/DeletedAt + Cloud present | PASS |
| New Cloud SaleHead soft-delete Op=D + source IsDeleted/DeletedAt + Local present | PASS |
| UserStatus `0/0/0` both sides | PASS |
| UserRights Local `1/1/0` Cloud `1/0/0` | PASS |

## Prerequisites

| Check | Result | Evidence |
|-------|--------|----------|
| Branch | PASS | `cursor/sb2-dev-test-bootstrap-9fc4` |
| Pull ff-only | PASS | `1dfdf7b` → `4f35d2e` (Treat detail hard-delete as applied and keep head soft-delete as Op=D) |
| HEAD is `4f35d2e` or descendant | PASS | HEAD=`4f35d2e9402974ff20bc85bf615b422e0a73e03c` |
| Did not rewind past `4debcfb`/`1dfdf7b` | PASS | Both remain ancestors |
| Env passwords | PASS | `SB2_DEV_LOCAL_SQL_PASSWORD` and `SB2_TEST_CLOUD_SQL_PASSWORD` SET (never printed) |
| No bak restore / no SB.exe rebuild / no service / no SB2-git | PASS | Not performed |

## Scripts

| Step | Result | Evidence |
|------|--------|----------|
| 1 LocalPendingFix | PASS | exit 0. Fix_AllEntry ok=41 skip=2. Generic refreshed. UserStatus/ListViewItem `0/0/0`; UserRights `1/1/0`. |
| 2 CloudAfterRestore (no `-EnableTxnC2L`) | PASS | exit 0. Fix_AllTxn ok=41 skip=2. `OK Detail Op=D hard delete; Head Op=D soft delete.` `OK UserRights L2C-only (TestCloud)`. UserStatus/ListViewItem `0/0/0`. Closed restored L2C=0; pre-agent Cloud C2L Pending=82 (left for agent). |
| 3 EncryptAndOnce | PASS | Built Release SyncAgent/SyncStatus; deployed NEW `SB.SyncAgent.exe` to runtime (LWT 2026-09-26 22:10:05 Asia/Rangoon, Len=26624, SHA256=`99510125ADE02BB3BD3E606AA4CBBE66B106DA3AB1E8C2C13150C1846FC487B8`); `/once` → `Sync cycle completed.` |

## After first `/once` (post EncryptAndOnce)

| Item | Local | Cloud | Result |
|------|-------|-------|--------|
| L2C Pending | **0** | **0** | PASS |
| C2L Pending | **0** | **0** | PASS |
| Syncing / DeadLetter | 0 / 0 | 0 / 0 | PASS |
| OutboxID 493 SaleDetail `{"ID":91986}` Op=D | (absent locally) | Status=**Synced**, SyncedAt=2026-09-26 15:40:25.639Z → **22:10:25 Asia/Rangoon**, LastError empty | PASS (must NOT stay Pending) |
| SyncAgent.log after new exe | No new `Pull failed OutboxID=493` after 22:10:07 Asia/Rangoon (prior failures were 21:22–21:23 with old exe) | — | PASS |

## Disposable Local SaleHead soft-delete (L2C)

| Step | Result | Evidence |
|------|--------|----------|
| Insert Local | PASS | ID=`45638` Remark=`DISP_20260926_221203_L2C_HEAD`; Outbox L2C Op=I → Synced after `/once`; Cloud row present |
| `UPDATE Deleted=1` on Local | PASS | Source Local: Deleted=1, **IsDeleted=1**, **DeletedAt=2026-09-26 15:42:48.106Z** (not null) |
| Outbox Op | PASS | OutboxID 332 L2C SaleHead **Operation=D** (not U) Status=Pending then Synced |
| After `/once` Cloud | PASS | Cloud ID=45638 **still present** Deleted=1 IsDeleted=1 |
| Pending after | PASS | Local+Cloud L2C/C2L Pending=0 |

## Disposable Cloud SaleHead soft-delete (C2L)

| Step | Result | Evidence |
|------|--------|----------|
| Insert Cloud | PASS | ID=`2000000000` (cloud zone) Remark=`DISP_20260926_221203_C2L_HEAD`; Outbox C2L Op=I → Synced; Local row present |
| `UPDATE Deleted=1` on Cloud | PASS | Source Cloud: Deleted=1, **IsDeleted=1**, **DeletedAt=2026-09-26 15:44:44.187Z** (not null) |
| Outbox Op | PASS | OutboxID 656 C2L SaleHead **Operation=D** Status=Pending then Synced |
| After `/once` Local | PASS | Local ID=2000000000 **still present** Deleted=1 IsDeleted=1 |
| Pending after | PASS | Local+Cloud L2C/C2L Pending=0 |

## SyncConfig flags (final)

| Table | Local IsEnabled/CaptureLocal/CaptureCloud | Cloud | Result |
|-------|-------------------------------------------|-------|--------|
| UserStatus | **0/0/0** | **0/0/0** | PASS |
| UserRights | **1/1/0** | **1/0/0** | PASS |
| ListViewItem | 0/0/0 | 0/0/0 | PASS |

## Sign-off

- **OVERALL PASS**
- HEAD verified: `4f35d2e`
- Results-only commit follows; EncryptAndOnce bin/obj dirt discarded (not committed).
- Written: 2026-09-26 22:15 Asia/Rangoon
