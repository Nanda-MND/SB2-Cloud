# SB2-Cloud Dev / Test acceptance results

## Current summary (2026-09-27)

This section is the current status. It supersedes the 2026-09-26 23:08 “Suite A IN PROGRESS” note, the Suite C SaleHead 45634 FAIL spot, and the fa016ed engineer note that still asked for a tighter Local reseed. Detailed tables below stay as written. This page does not turn the original 113-cell Suite A run into an all-PASS matrix.

| Item | Status |
|------|--------|
| Fail-only at `fa016ed`, recorded in `49dd869` | PASS 10/10. Needed a manual Local reseed of ReturnStock/GetStock to `MAX(ID) < 1999999999`. |
| LocalPendingFix assert at `17ac27f`; retest at `08fbf0b`; results at `83c9288` | PASS 10/10. No manual reseed. |
| `IDENT_CURRENT` | Local ReturnStock/GetStock Head and Detail `<< 1999999999`. Cloud `>= 2000000000`. |
| SaleHead 45634 | PASS. Cloud `Deleted=1`, `IsDeleted=1`, `DeletedAt` set. Not hard-deleted. |

Evidence stays on disk only: `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\failonly_20260927_095448\` and `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\new folder\failonly17_20260927_104650\`. The all-txn folder `all_txn_20260926_225738` finished PASS=113 FAIL=9 SKIP=6. Those nine cells plus SaleHead 45634 were the fail-only set. Journal/Manufacture/Stock meta stayed SKIP.

### Suite A prep (no runner script in this repo)

`Run_SuiteA_AllTxn_Matrix.ps1` is not in the git tree. Before a fail-only or matrix run on the Dev PC:

1. `docs/sql/SB2_Run_LocalPendingFix.ps1` on localhost / SB2. Stop if it aborts because ReturnStock or GetStock `IDENT_CURRENT >= 1999999999`.
2. `docs/sql/SB2_Run_CloudAfterRestore.ps1` with no `-EnableTxnC2L`.
3. `SB.SyncAgent/SB2_Dev_EncryptAndOnce.ps1`.

L2C disposable inserts omit the ID column. Never `IDENTITY_INSERT` a cloud-zone ID on Local, and never hardcode `2000000000` on Local.

---

## Prior: Purchase* + Transfer* 12-cell (2026-09-26 22:43 Asia/Rangoon)

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


---

## 2026-09-26 23:08 Asia/Rangoon (UTC+6:30) — superseded evidence note

Superseded by the current summary at the top. SaleHead 45634 later PASS (`IsDeleted=1`). Suite A left IN PROGRESS here; the run then finished PASS=113 FAIL=9 SKIP=6, and the nine FAIL cells passed on the fail-only re-runs. Do not treat this note as current, and do not invent a 113-cell PASS from it.

- **Suite C read-only spot (historical):** FAIL for SaleHead `45634` (`Cloud Deleted=1 IsDeleted=0`); other soft remnants/Purchase/Transfer checks PASS.
- **Suite A all-txn matrix (historical):** was IN PROGRESS at `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\all_txn_20260926_225738\`.

---

## 2026-09-27 10:01 Asia/Rangoon (UTC+6:30) — Fail-only re-run after fa016ed identity fix

**Tester:** Nanda-HP (`e921257a-2870-4ad6-9b01-cfd6b497ecc4`)  
**Repo:** `D:\Project\SB2-Cloud` = `Nanda-MND/SB2-Cloud`  
**Branch:** `cursor/sb2-dev-test-bootstrap-9fc4`  
**HEAD:** `fa016ed4c6fa0fef1dc48453d73ab5be7be26f65` (`fa016ed` — Keep new cloud IDs at or above 2e9 and pull Local identities back down.)  
**Ancestors:** `fa016ed`, `c71f1ca`, `4e81dd8` all OK (no rewind).  
**Evidence:** `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\failonly_20260927_095448\` (not git-added)  
**Constraints honored:** No bak restore; no SB.exe rebuild/replace; no Windows service SB.SyncAgent; no Live/Client; no SB2-git / Production MSSQL; passwords from env only (never printed); L2C inserts omit ID column (no IDENTITY_INSERT / no hardcoded 2000000000 on Local).

### OVERALL: **PASS**

Every required fail-only cell PASS; both DBs L2C Pending=0 and C2L Pending=0 after last `/once`.

### Prep

| Step | Result | Evidence |
|------|--------|----------|
| git fetch / checkout / pull --ff-only | PASS | `5a552ad` → `fa016ed` |
| `SB2_Run_LocalPendingFix.ps1` (localhost/SB2/sa) | PASS (exit 0) | Fix_AllEntry ok; Generic refreshed; UserStatus/ListViewItem off. Script pull-down left ReturnStock*/GetStock* at IDENT_CURRENT=1999999999 (next~2e9) because prior junk rows at ID=1999999999 exist; **Tester additionally reseeds those four tables to true local max ID&lt;1999999999** (Heads→2, Details→1) so next Local insert &lt;&lt; 2e9. |
| `SB2_Run_CloudAfterRestore.ps1` (no `-EnableTxnC2L`) | PASS (exit 0) | ReturnStockHead/GetStockHead RESEED next ~**2000000004** (cloud zone). ReturnStockDetail/GetStockDetail next ~2000000000 (OK_NEXT_AT_FLOOR; never allocates 1999999999 as new ID). |
| `SB.SyncAgent\SB2_Dev_EncryptAndOnce.ps1` | PASS (exit 0) | NEW SyncAgent deployed: LWT **2026-09-27 09:49:28 Asia/Rangoon**, Len=**27136**, SHA256=`CD5C05122F3DF7A1FB1AF179D5F04907427E4BE2D9B4AF113E585DFD221654F4`; `/once` → Sync cycle completed. Second `/once` cleared residual Cloud C2L Detail Op=D Pending (15→0). |
| Pre-cell Local+Cloud L2C/C2L Pending=0 | PASS | After second `/once` |

### Fail-only cells (do not re-run the 113 PASS cells)

| Cell | Result | Evidence |
|------|--------|----------|
| ReturnStock_NEW_C2L | **PASS** | CloudHead=**2000000004** Detail=2000000000; Local present; zone2e9=True; fail1999=False; Pending0 |
| GetStock_NEW_C2L | **PASS** | CloudHead=**2000000004** Detail=2000000000; Local present; zone2e9=True; fail1999=False; Pending0 |
| ReturnStock_DETHARD_L2C | **PASS** | Local Head=**3** Detail=2 (&lt;&lt;2e9); no Msg 2627; both sides detail absent; Det Op=D left=0/0; Pending0. (Requires true-local reseed after C2L NEW — see note.) |
| ReturnStock_HEADSOFT_L2C | **PASS** | Local Head=**4**; Op=**D** (not U); Src Deleted=1 IsDeleted=1 DeletedAt set; Cloud present 1/1; Det Op=D absent both; Pending0 |
| GetStock_DETHARD_L2C | **PASS** | Local Head=**3** Detail=2; Labsent=0 Cabsent=0; Det Op=D left=0/0; Pending0 |
| GetStock_HEADSOFT_L2C | **PASS** | Local Head=**4**; Op=D; Src 1/1; Cloud 1/1 present; Det Op=D absent; Pending0 |
| StockReceive_EDIT_L2C | **PASS** | Head=**71**; CloudMatch=1; Pending0 (no transport retry needed) |
| SupplierOpening_EDIT_C2L | **PASS** | Head=**2000000004** zone2e9; LocalMatch=1; Pending0 |
| ReturnReceive_HEADSOFT_C2L | **PASS** | Head=**2000000004**; OpD=1 Src=1 Local11=1 Present=1; Pending0 |
| SaleHead 45634 (Cloud) | **PASS** | Deleted=**1**, IsDeleted=**1**, DeletedAt=**2026-09-27 03:18:34.843** (not null). Not hard-deleted. |

### After last `/once` — Pending Direction/Status counts

| DB | Pending/Syncing/DeadLetter | Other |
|----|----------------------------|-------|
| Local | **none** (L2C Pending=0, C2L Pending=0) | L2C Synced=389 |
| Cloud | **none** (L2C Pending=0, C2L Pending=0) | C2L Synced=241; L2C Synced=216; C2L Conflict=2 (pre-existing LocalWinsSkipped; not Pending) |

### Notes for engineers

1. **Cloud NEW zone fixed by fa016ed:** prior Suite A fail had CloudHead=1999999999; this run allocates ≥2000000000.
2. **Local L2C after C2L (closed by `17ac27f`):** this fa016ed run still used `MAX(ID) WHERE ID < 2000000000`, which landed on **1999999999**, so Tester hand-reseeded before the L2C cells. `17ac27f` reseeds to `MAX(ID) WHERE ID < 1999999999` and aborts `LocalPendingFix` if ReturnStock/GetStock stay at the sentinel. The 10:54 re-run (results `83c9288`) passed with no manual reseed.
3. EncryptAndOnce bin/obj dirt discarded (not committed). Evidence folder not git-added.

### Sign-off

- **OVERALL PASS**
- HEAD: `fa016ed`
- Results-only commit follows.

---

## 2026-09-27 — Suite A 9 FAIL cells: fix commits

Code on `cursor/sb2-dev-test-bootstrap-9fc4` at `17ac27f`. This section records the commits. It is not a new matrix run.

| Target | Commit | What changed |
|--------|--------|----------------|
| ReturnStock_NEW_C2L, GetStock_NEW_C2L landed at CloudHead `1999999999` | `fa016ed` | `Cloud_Reseed_TransactionIdRanges.sql` reseeds a never-generated identity to `2000000000`. ReturnStock and GetStock Head/Detail are in that list. `SB2_Run_CloudAfterRestore.ps1` runs it. |
| ReturnStock/GetStock DETHARD and HEADSOFT L2C Msg 2627 on Local ID `2000000000` | `fa016ed`, tightened by `17ac27f` | L2C inserts omit the ID column. After C2L, Local identity is pulled to `MAX(ID)` where `ID < 1999999999` (or `0` when no true-local row exists). `LocalPendingFix` aborts if ReturnStock/GetStock Head or Detail `IDENT_CURRENT` is still `>= 1999999999`. |
| SaleHead 45634 Cloud `Deleted=1` `IsDeleted=0` | `4f35d2e`, repair in `fa016ed` | Head `Deleted=1` sets source `IsDeleted=1` and `DeletedAt` and enqueues Op=D. `SB2_Repair_HeadSoftDelete_Flags_CLOUD.sql` repairs older Cloud rows, including 45634, and does not queue outbox. |
| StockReceive_EDIT_L2C, SupplierOpening_EDIT_C2L, ReturnReceive_HEADSOFT_C2L transport timeouts | `fa016ed` | `SyncEngine` retries a row up to 3 times on TCP, SSL, Named Pipes, or timeout (`maxAttempts = 3`). |

The fa016ed fail-only section above passed only after a manual reseed. That gap is closed: the 10:54 re-run at `08fbf0b` (results `83c9288`) passed 10/10 with `LocalPendingFix` only and no manual reseed. Cloud reseed is unchanged, so Cloud next stays `>= 2000000000`.


---

## 2026-09-27 10:54 Asia/Rangoon (UTC+6:30) - Fail-only re-run after 17ac27f (no manual Local reseed)

**Tester:** Nanda-HP (`e921257a-2870-4ad6-9b01-cfd6b497ecc4`)  
**Repo:** `D:\Project\SB2-Cloud` = `Nanda-MND/SB2-Cloud`  
**Branch:** `cursor/sb2-dev-test-bootstrap-9fc4`  
**HEAD:** `08fbf0ba5a742bbaf2538e50df1f610bd7ae30c9` (`08fbf0b` - docs: map Suite A fail cells to the identity and soft-delete commits.)  
**Ancestors:** `17ac27f`, `fa016ed`, `49dd869`, `4e81dd8`, `c71f1ca` all OK (no rewind).  
**Evidence:** `D:\Dev\SB2-Cloud-Runtime\e2e_evidence\new folder\failonly17_20260927_104650\` (not git-added)  
**Marker:** `E2E_ALLTXN_20260927_105135`  
**Constraints honored:** No bak restore; no SB.exe rebuild/replace; no Windows service SB.SyncAgent; no Live/Client; no SB2-git / Production MSSQL; passwords from env only (never printed); L2C inserts omit ID column (no IDENTITY_INSERT / no hardcoded 2000000000 on Local); **no manual Local reseed** (`17ac27f` SyncApply + LocalPendingFix only).

### OVERALL: **PASS**

Every required fail-only cell PASS; both DBs L2C Pending=0 and C2L Pending=0 after last `/once`. No Msg 2627. Cloud NEW IDs >=2e9 (not 1999999999). Local DETHARD/HEADSOFT Heads <<2e9.

### Prep

| Step | Result | Evidence |
|------|--------|----------|
| git fetch / checkout / pull --ff-only | PASS | HEAD `08fbf0b` (was behind 2 at `49dd869`; ff to `08fbf0b`) |
| `SB2_Run_LocalPendingFix.ps1` (localhost/SB2/sa) | PASS (exit 0) | Fix_AllEntry ok=41 skip=2; Generic refreshed; UserStatus/ListViewItem off. ASSERT ReturnStockHead=4, ReturnStockDetail=1, GetStockHead=4, GetStockDetail=1. No abort `IDENT_CURRENT is still >= 1999999999`. |
| `SB2_Run_CloudAfterRestore.ps1` (no `-EnableTxnC2L`) | PASS (exit 0) | Detail hard / Head soft OK; UserRights L2C-only (TestCloud). Cloud ReturnStockHead/GetStockHead IDENT_CURRENT=2000000004; Details=2000000000. |
| `SB.SyncAgent\SB2_Dev_EncryptAndOnce.ps1` clean rebuild | PASS (exit 0) | Cleaned SyncAgent/SyncStatus bin+obj; Rebuild. Deployed Len=**27136**, SHA256=`CF5992040B20A586EC8C91754B9695F1A606039C0DFDE5C73AC4AC6F12F012BF`, LWT **2026-09-27 10:48:45 Asia/Rangoon**; `/once` completed. Extra `/once` drained 16 residual Cloud C2L Detail Op=D Pending left after CloudAfterRestore (742..966)  0. |
| IDENT_CURRENT 4x2 pre-cells | PASS | Local RS/GS Head/Detail = 4/1/4/1 (<<2e9). Cloud = 2000000004/2000000000/2000000004/2000000000 (>=2e9). |
| Pre-cell Pending=0 both | PASS | After drain `/once` |

### Fail-only cells (do not re-run the 113 PASS cells)

| Cell | Result | Evidence |
|------|--------|----------|
| ReturnStock_NEW_C2L | **PASS** | CloudHead=**2000000005** Detail=2000000001; Local present; zone2e9=True; fail1999=False; Pending0 |
| GetStock_NEW_C2L | **PASS** | CloudHead=**2000000005** Detail=2000000001; Local present; zone2e9=True; fail1999=False; Pending0 |
| ReturnStock_DETHARD_L2C | **PASS** | Local Head=**5** Detail=2 (<<2e9); no Msg 2627; both sides detail absent; Det Op=D left=0/0; Miss=0; Pending0. Auto-reseed via SyncApply after C2L (`17ac27f`) - no hand reseed. |
| ReturnStock_HEADSOFT_L2C | **PASS** | Local Head=**6**; Op=**D** (not U); Src Deleted=1 IsDeleted=1 DeletedAt set; Cloud present 1/1; Det Op=D absent both; Pending0 |
| GetStock_DETHARD_L2C | **PASS** | Local Head=**5** Detail=2; Labsent=0 Cabsent=0; Det Op=D left=0/0; Miss=0; Pending0 |
| GetStock_HEADSOFT_L2C | **PASS** | Local Head=**6**; Op=D; Src 1/1; Cloud 1/1 present; Det Op=D absent; Pending0 |
| StockReceive_EDIT_L2C | **PASS** | Head=**72**; CloudMatch=1; Pending0 |
| SupplierOpening_EDIT_C2L | **PASS** | Head=**2000000005** zone2e9; LocalMatch=1; Pending0 |
| ReturnReceive_HEADSOFT_C2L | **PASS** | Head=**2000000005**; OpD=1 Src=1 Local11=1 Present=1; Pending0 |
| SaleHead 45634 (Cloud) | **PASS** | Deleted=**1**, IsDeleted=**1**, DeletedAt=**2026-09-27 03:18:34.843** (not null). Not hard-deleted. |

### After last `/once` - Pending Direction/Status counts

| DB | Pending/Syncing/DeadLetter | Other |
|----|----------------------------|-------|
| Local | **none** (L2C Pending=0, C2L Pending=0) | L2C Synced=401 |
| Cloud | **none** (L2C Pending=0, C2L Pending=0) | C2L Synced=249; L2C Synced=216; C2L Conflict=2 (pre-existing; not Pending) |

### Notes for engineers

1. **`17ac27f` verified without manual Local reseed.** Prior fa016ed fail-only PASS required Tester hand-reseed of ReturnStock*/GetStock* to MAX(ID)<1999999999. This run used only LocalPendingFix ASSERT + SyncApply_Generic post-C2L pull-down; L2C Local Heads landed at 5/6 (<<2e9), no Msg 2627.
2. CloudAfterRestore can leave Cloud C2L Detail Op=D Pending; EncryptAndOnce `/once` alone may not drain them all if cycle timing races - one extra `/once` cleared 160 before baseline.
3. EncryptAndOnce bin/obj dirt discarded (not committed). Evidence folder not git-added.

### Sign-off

- **OVERALL PASS**
- HEAD: `08fbf0b` (contains `17ac27f` / `fa016ed`)
- Results-only commit follows.

