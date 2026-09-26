# SB2-Cloud Dev / Test acceptance results

Date: 2026-09-26 22:43 Asia/Rangoon (UTC+6:30)
HEAD: `4e81dd821e421a14d1a21d914c8dc856ccfadf0b` (`4e81dd8`)
Branch: `cursor/sb2-dev-test-bootstrap-9fc4`
Run: Purchase* + Transfer* 12-cell edit/delete sync matrix
Machine: Nanda-HP (`e921257a-2870-4ad6-9b01-cfd6b497ecc4`)
Runtime: `D:\Dev\SB2-Cloud-Runtime\`
Targets: Local `localhost` / `SB2` (sa); Cloud `sql8006.site4now.net` / `db_abe8c0_sb2`
Markers: `E2E_PUR_20260926_223311` / `E2E_XFR_20260926_223311`
No fresh bak restore. No SB.exe rebuild. No Windows service. No SB2-git. No Live/Client. Passwords from env only (never printed).

## Summary

**OVERALL: PASS**

| Check | Result |
|-------|--------|
| Pull ff-only; HEAD `4e81dd8` or descendant | PASS (HEAD=`4e81dd8`) |
| Did not rewind past `4f35d2e`/`4e81dd8` | PASS |
| `SB2_Run_LocalPendingFix.ps1` | PASS (exit 0; Fix_AllEntry ok=41 skip=2) |
| `SB2_Run_CloudAfterRestore.ps1` (no `-EnableTxnC2L`) | PASS (exit 0; Detail hard / Head soft OK; UserRights L2C-only) |
| `SB2_Dev_EncryptAndOnce.ps1` + clean Rebuild SyncAgent | PASS (Len=26624 SHA256=`55937CD1E3A763EA35B54E51C43D3EFCFB193086CF85557D54145815E82E4CD3` LWT 2026-09-26 22:32:31 Asia/Rangoon) |
| Pre-matrix Local+Cloud L2C/C2L Pending=0 | PASS (after Outbox 493 SaleDetail Synced with fixed agent) |
| Purchase* 6/6 | PASS |
| Transfer* 6/6 | PASS (F via recheck after transport flake) |
| Final Pending all 0 | PASS |
| UserStatus `0/0/0` both | PASS |
| UserRights Local `1/1/0` Cloud `1/0/0` | PASS |

## 12-cell matrix

| Cell | Result | Evidence |
|------|--------|----------|
| Purchase A L2C Edit Head | **PASS** | Local PurchaseHead ID=3917 Remark→`E2E_PUR_20260926_223311_L2C_EDIT`; /once; Cloud Remark matched; Pending 0 |
| Purchase B L2C Detail hard-delete | **PASS** | Local DELETE PurchaseDetail ID=20419 (Head=3918); both ABSENT; Pending 0; no Applied-but-row-missing |
| Purchase C L2C Head soft-delete | **PASS** | Local PurchaseHead ID=3919 Deleted=1; Outbox Op=**D** (not U); source IsDeleted=1 DeletedAt set; Cloud PRESENT Deleted=1 IsDeleted=1; Pending 0 |
| Purchase D C2L Edit | **PASS** | Cloud PurchaseHead ID=**2000000001** (≥2e9) Remark→`..._C2L_EDIT`; Local matched; Pending 0 |
| Purchase E C2L Detail hard-delete | **PASS** | Cloud DELETE PurchaseDetail ID=2000000000 (Head=2000000002); both ABSENT; MissErr=0; Pending 0 |
| Purchase F C2L Head soft-delete | **PASS** | Cloud PurchaseHead ID=2000000003 Deleted=1; Outbox Op=**D**; source IsDeleted=1 DeletedAt set; Local PRESENT 1/1; Pending 0 |
| Transfer A L2C Edit Head | **PASS** | Local TransferHead ID=2399 Remark→`E2E_XFR_20260926_223311_L2C_EDIT`; Cloud matched; Pending 0 |
| Transfer B L2C Detail hard-delete | **PASS** | Local DELETE TransferDetail ID=20759 (Head=2400); both ABSENT; Pending 0 |
| Transfer C L2C Head soft-delete | **PASS** | Local TransferHead ID=2401 Deleted=1; Outbox Op=**D**; source IsDeleted=1 DeletedAt set; Cloud PRESENT 1/1; Pending 0 |
| Transfer D C2L Edit | **PASS** | Cloud TransferHead ID=**2000000000** (≥2e9) Remark→`..._C2L_EDIT`; Local matched; Pending 0 |
| Transfer E C2L Detail hard-delete | **PASS** | Cloud DELETE TransferDetail ID=2000000000 (Head=2000000001); both ABSENT; MissErr=0; Pending 0 |
| Transfer F C2L Head soft-delete | **PASS** | First matrix attempt: Cloud TransferHead ID=2000000002 Op=D OutboxID=751 left Pending after `Sync cycle error: TCP Provider semaphore timeout`; Local still Deleted=0. Immediate retry /once → Outbox 751 **Synced**, Local 1/1. Clean recheck: new Cloud ID=**2000000004** Op=D source flags 1/1; /once; Local PRESENT 1/1; Pending 0 |

## SKIP

| Item | Reason |
|------|--------|
| Pre-existing Cloud-zone Purchase/Transfer heads | None present before matrix; C2L cells used fresh Cloud inserts (IDENT_CURRENT 1999999999 → IDs ≥2e9) |

## Pending (final)

| Side | L2C Pending | C2L Pending | Syncing/DeadLetter |
|------|-------------|-------------|--------------------|
| Local | **0** | **0** | 0 |
| Cloud | **0** | **0** | 0 |

## Known-good (no regress)

| Item | Result |
|------|--------|
| Sale* prior 6/6 + Op=D soft-delete | Not re-run; residual Outbox 493 SaleDetail cleared to **Synced** by fixed SyncAgent (was Pending again after CloudAfterRestore until clean rebuild Len=26624) |
| UserStatus both `0/0/0` | PASS |
| UserRights Local `1/1/0` Cloud `1/0/0` | PASS |
| Detail hard / Head soft | PASS (asserted in CloudAfterRestore + matrix cells) |
| New SyncAgent via EncryptAndOnce | PASS (clean Rebuild required; incremental deploy briefly left stale 23552-byte exe) |

## Agent fix bullets

1. **Transient Cloud TCP during long matrix:** First `Transfer_F` `/once` hit `transport-level error / semaphore timeout`; OutboxID **751** TransferHead Op=D stayed Pending with AttemptCount=0 and empty LastError; Local row not updated. Retry `/once` applied successfully. Not a SyncApply/Op logic defect (recheck PASS on ID 2000000004). Consider agent retry-on-transport for C2L pull.
2. **EncryptAndOnce incremental build risk:** Without cleaning `bin/obj`, a stale smaller `SB.SyncAgent.exe` (23552) was deployable and left Outbox 493 failing `Applied but row missing`; clean Rebuild restored 26624-byte binary with detailHardDelete skip and 493→Synced. Prefer clean rebuild in the EncryptAndOnce path on Tester.

## Evidence

- Folder (not in git): `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\`
- Matrix runner: `Run_PurXfr_Matrix.ps1`; `matrix_results.json`; `Transfer_F_recheck.json`
- SyncAgent runtime SHA256=`55937CD1E3A763EA35B54E51C43D3EFCFB193086CF85557D54145815E82E4CD3`

## Sign-off

- **OVERALL PASS** — 12/12 runnable cells PASS; final Pending all 0.
- Results-only commit; SyncAgent/SyncStatus bin/obj dirt discarded (not committed).
- Written: 2026-09-26 22:43 Asia/Rangoon

---

## Prior runs (retained)

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

