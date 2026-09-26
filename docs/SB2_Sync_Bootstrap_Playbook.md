# SB2-Cloud Sync Bootstrap Playbook

Port **SB** Local↔Cloud sync (L2C / C2L) + **SyncAgent** + **Tray (SyncStatus)** + **UserRights** into a **new repo `SB2-Cloud`**.

## Repo & environment (mandatory)

| Rule | Detail |
|------|--------|
| New repo | Work in **`SB2-Cloud`** — do **not** change live **SB** production repo |
| SB2-git | Read-only reference (`D:\Project\SB2-git`, `Nanda-MND/SB2.git`). Do not commit, push, or edit it. Do not delete or recreate the SB2-Cloud folder from it. |
| First target | **Dev PC Local SQL** + **Test Cloud** only |
| Forbidden (until Dev green) | Live/production DB, Client PC ERP folder, live SyncAgent on customer PCs |
| Cutover | Separate task after `docs/SB2_DEV_TEST_RESULTS.md` is green |

## Open the app (Dev PC)

Open `SB.sln` in Visual Studio. The solution contains `SB`, `SB.SyncAgent`, and `SB.SyncStatus`. Set **SB** as the startup project and press F5 (Debug). The history window title is `SB`. Menus `Sales`, `Cashbook`, and `Balance` exercise H1–H8 on the recovered history list.

Build output is `SB\bin\Debug\SB.exe`. That folder is gitignored. Do not replace it with `D:\Project\SB2-git\SB\Bin\Debug`. This sandbox does not edit SB2-git.

`DBConnection.ini` is not in git. Sync still uses `D:\Dev\SB2-Cloud-Runtime\` via `SB2_Dev_EncryptAndOnce.ps1`.

## DEV / TEST names (this phase)

Filled from `docs/config/SB2_CONNECTIONS.md`. Passwords are not in git.

| Key | Value |
|-----|-------|
| Environment | `DEV_TEST` |
| Dev Local | `localhost` / database `SB2` / user `sa` (default instance). `.`, `(local)`, and `127.0.0.1` are the same instance. `local\SB2` is not installed. |
| Test Cloud | `sql8006.site4now.net` (runners connect as `tcp:sql8006.site4now.net,1433`) / `db_abe8c0_sb2` / `db_abe8c0_sb2_admin` |
| ERP runtime folder | `D:\Dev\SB2-Cloud-Runtime\` (no `.git`) |
| Git checkout | `D:\Dev\SB2-Cloud\` — scripts and source only. Do not write `DBConnection.ini` here. |
| Windows service | `SB2.SyncAgent.Dev` |
| RC4 EncryptKey | `27042005` |
| Refused | SB1, `SQL1002.site4now.net`, `db_abbe78_warehouse`, `db_abe8c0_erp`, `db_abe8c0_luckyone`, client folder `D:\MinnNandar\Software` |
| Live later | Change this table when the live connection is approved. Do not point this test run at live. |

Runners:

1. `docs/sql/SB2_Run_LocalBootstrap.ps1` — Dev Local. UserRights L2C-only. Detail Op=D hard delete.
2. `docs/sql/SB2_Run_Backup.ps1` — COPY_ONLY backup of Dev Local.
3. `docs/sql/SB2_Run_TestCloudRestore.ps1` — restore that `.bak` onto Test Cloud only.
4. `docs/sql/SB2_Run_CloudAfterRestore.ps1` — Test Cloud scripts. Does not install Local capture. Reseeds cloud transaction identities (including Fix_AllTxn-only tables), turns UserStatus and ListviewItem sync off, and closes restored Cloud L2C outbox copies.
5. `docs/sql/SB2_Run_LocalPendingFix.ps1` — Local only. Reinstalls entry L2C triggers (head soft-delete Op=D and source `IsDeleted=1`), refreshes Generic, and turns UserStatus/ListviewItem off. No identity reseed.
6. `SB.SyncAgent/SB2_Dev_EncryptAndOnce.ps1` — encrypt Dev/Test ini, `/once`, optional service `SB2.SyncAgent.Dev`.

Older `docs/sql/Deploy-*.cmd` launchers that pointed at SB1 or the production cloud host now exit through `SB2_RefuseLive.cmd`.

Assert scripts are not the first step. On a new `SB2` database, `dbo.SyncConfig` does not exist yet.

1. Run `SB2_Run_LocalBootstrap.ps1`. It installs sync, then calls `SB2_Assert_DetailHardDelete.sql` and `SB2_Assert_UserRights_L2C.sql` with `sqlcmd -v Role=Local`.
2. Backup, restore onto Test Cloud, then run `SB2_Run_CloudAfterRestore.ps1`. That runner calls the UserRights assert with `sqlcmd -v Role=TestCloud`.
3. Do not run the assert files alone before bootstrap. A direct `sqlcmd` without `-v Role=` warns that the scripting variable is not defined.

Passwords stay in `SB2_DEV_LOCAL_SQL_PASSWORD` and `SB2_TEST_CLOUD_SQL_PASSWORD`. Do not commit them. Placeholders in `docs/config/SB2_CONNECTIONS.md` stay placeholders.

## Source of truth (reference SB repo — copy from, do not edit for this port)

| Area | Where in SB |
|------|-------------|
| Architecture | `docs/DATA_SYNC_ARCHITECTURE.md` |
| Client deploy | `docs/DATA_SYNC_CLIENT_DEPLOYMENT.md`, `docs/CLIENT_PC_DEPLOY.md` |
| Connections pattern | `docs/config/CLIENT_CONNECTIONS.md` |
| Agent | `SB.SyncAgent/` (`DBConnection.ini`, `CloudConnection.ini`, RC4 key `27042005`) |
| Tray | `SB.SyncStatus/` |
| Core SQL | `docs/sql/DataSync_01_Schema.sql` … `DataSync_15_*.sql`, `DataSync_28_*.sql` |
| Detail hard-delete | `Deploy_TxnDetail_HardDeleteSync_LOCAL/CLOUD.sql` |
| Head soft-delete finish | `Deploy_EditDeleteSync_LOCAL/CLOUD.sql` |
| UserRights L2C-only | `DataSync_UserRights_L2C_Only.sql` + `_Local.sql` |
| Entry rights policy | `README_UserEntryRights_Deploy.md` |
| Cursor paste prompt | `docs/SB2_PORT_PROMPT.md` |
| History ListView UX | `docs/SB2_HistoryListView_Port.md` |

## Target flow (required) — Dev / Test only

```text
┌──────────────────────────────────┐
│ 0. New repo SB2-Cloud            │  copy scripts/agent/UI from SB reference
└──────────────┬───────────────────┘
               ▼
┌──────────────────────────────────┐
│ 1. Prepare DEV LOCAL completely  │  schema + capture + UserRights + verify
└──────────────┬───────────────────┘
               │ backup .bak
               ▼
┌──────────────────────────────────┐
│ 2. Restore .bak → TEST CLOUD DB  │  schema/data parity (not production)
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ 3. Test-Cloud-only scripts       │  C2L capture, CaptureCloud flags,
│                                  │  UserRights C2L off, Detail/Head packs
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ 4. SyncAgent + Tray on DEV PC    │  Dev Local + Test Cloud ini only
└──────────────┬───────────────────┘
               ▼
┌──────────────────────────────────┐
│ 4b. History ListView UX on DEV   │  footer, progress, MultiSelect, columns
└──────────────┬───────────────────┘
               ▼
┌──────────────────────────────────┐
│ 5. Acceptance Dev↔Test + H1–H8   │  then STOP — ask before Live/Client
└──────────────────────────────────┘
```

Why Local-first restore: SyncAgent syncs **data**, not DDL. Restoring Dev Local→Test Cloud avoids missing columns/procs on Cloud.

---

## Phase checklist

### A. Connections (DEV / TEST only)

Fill from `docs/config/SB2_CONNECTIONS.template.md` → `SB2_CONNECTIONS.md` in **SB2-Cloud**.  
Use **Dev PC Local + Test Cloud** only. **Do not commit passwords.**  
Do not put Live/Client endpoints in this phase.

Encrypted files next to agent (names must match `ConnectionIni.cs`):

| File | Points to |
|------|-----------|
| `DBConnection.ini` | Dev Local |
| `CloudConnection.ini` | Test Cloud |

```cmd
SB.SyncAgent.exe /encrypt DBConnection.ini "Data Source=DEV_PC\INSTANCE;Initial Catalog=SB2;User Id=sa;Password=***;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
SB.SyncAgent.exe /encrypt CloudConnection.ini "Data Source=TEST_CLOUD_HOST;Initial Catalog=TEST_DB;User Id=***;Password=***;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
```

Confirm SB2 WinForms uses the **same RC4 key** as the agent (`27042005` in SB).

### B. DEV LOCAL scripts (before Test Cloud restore)

Order (or run `docs/sql/SB2_Run_LocalBootstrap.ps1` with **Dev** `-Server`/`-Database`):

1. `DataSync_01_Schema.sql`
2. `DataSync_04_SoftDelete_Migration.sql`
3. `DataSync_10_SyncApply_Generic.sql` — require marker `hardDeleteDetail`
4. `DataSync_03_ApplyInbound.sql` (if present)
5. `DataSync_11_AllTables_Install.sql` + `DataSync_11_RunLocal.sql` (`InstallCapture=1`)
6. `DataSync_14_MasterPriority.sql`
7. `DataSync_15_ERPTransactionTables.sql` (if applicable)
8. `Deploy_TxnDetail_HardDeleteSync_LOCAL.sql`
9. `Deploy_EditDeleteSync_LOCAL.sql`
10. UserRights / menus / reports:
   - `Update_AllowDelete_AdminUsers_MenuID2.sql` (adjust UserIDs for SB2)
   - `DataSync_UserRights_L2C_Only_Local.sql`
   - report grants / clones as in SB `README_Users14_16_RunPack.md` / `README_UserEntryRights_Deploy.md`
   - `Fix_Duplicate_UserRights_BothSides.sql` if duplicates appear

Local guards in scripts: abort if DB name looks like production Cloud.  
For Dev: allow Dev DB name (e.g. `SB2`); reject live warehouse names.

### C. Backup → Test Cloud restore

1. Full backup of **Dev Local** after B succeeds.
2. Restore onto **Test Cloud** host only (never production cloud).
3. Fix logical file names / paths per host.
4. Smoke: `SELECT DB_NAME(); SELECT TOP 1 * FROM dbo.SyncConfig;`

### D. TEST CLOUD-only scripts (after restore)

Or run `docs/sql/SB2_Run_CloudAfterRestore.ps1` against **Test Cloud** (+ `-EnableTxnC2L` if needed):

1. Re-apply `DataSync_10_SyncApply_Generic.sql` if backup predates latest Generic.
2. `DataSync_28_EnableC2L_Capture.sql`
3. Enable C2L only for tables that Cloud may edit (do **not** turn CaptureLocal=1 on Cloud).
4. `Deploy_TxnDetail_HardDeleteSync_CLOUD.sql`
5. `Deploy_EditDeleteSync_CLOUD.sql`
6. `DataSync_UserRights_L2C_Only.sql` on Cloud
7. `Cloud_Reseed_TransactionIdRanges.sql` on Cloud only, then `Fix_AllTxn_Cloud_C2L_Capture.sql` (`CaptureCloud=1`, `CaptureLocal=0`). Reseed floor `2000000000`. Covers every Fix_AllTxn identity table (ReturnReceive, StockOpening, RawIssue, FinishGoods, ReturnStock, GetStock, Account/Customer/Supplier/Manufacturer opening, CustSupTransfer, plus Sale/Purchase/Transfer/Adjustment/StockReceive/IncomeExpense/Journal). Missing tables SKIP. The reseed script aborts if `DB_NAME()` is `SB2`, `SB1`, or `SB`. Never `DBCC CHECKIDENT` Local up to that floor.
8. `SB2_Disable_UserStatus_And_Listview_Sync.sql` on **both** Local and Cloud. UserStatus: `IsEnabled=0`, `CaptureLocal=0`, `CaptureCloud=0`, Sync triggers dropped, pending outbox removed. `dbo.UserStatus_CleanupGhosts` stays; CloudAfterRestore runs `Cloud_UserStatus_GhostCleanup.sql` after the disable so the proc exists after a fresh restore. ListviewItem is not a sync table (UI widths only). `Users` stays a master (`DataSync_15`). UserRights is unchanged.
9. `SB2_Close_RestoredCloud_L2C_Outbox.sql` on Cloud only. Restored `Direction=L2C` rows are a copy of Local's queue; the agent never claims them on Cloud. C2L rows stay. Do not run this on Local.
10. Optional: Sale/Purchase/Transfer C2L packs from SB (`DataSync_32/35/36…`) if SB2 needs same bidirectional txn edits

Head `Op=D` is a soft `IsDeleted` update. Detail `Op=D` is a physical DELETE. Apply compares the primary key with `TRY_CAST` so an int key is not compared to `sql_variant` (that throw left PurchaseHead `Op=D` Pending).

Cloud note: after Local→Cloud restore the catalog name may still be `SB2`.  
Do **not** rely on `DB_NAME()='SB2'` alone to detect Local. This phase restores onto `db_abe8c0_sb2`. The reseed and L2C-close scripts abort when the catalog is `SB2` so a manual run cannot reseed or skip Local's live queue.

### E. Agent + Tray on DEV PC only

1. Build Release SyncAgent + SyncStatus.
2. Copy into **Dev** ERP/test folder (not Client PC).
3. Encrypt ini files for Dev Local + Test Cloud (Phase A).
4. `SyncAgent.exe /once` (or `/test`).
5. Optional: install Windows service with a **Dev-specific** name.
6. Start tray; confirm Pending drains Dev↔Test Cloud.

### F. Acceptance (Dev↔Test)

Use `docs/SB2_DEV_TEST_RESULTS.template.md`.

Also complete **History ListView** port (`docs/SB2_HistoryListView_Port.md`) on Dev PC:
footer summary + Spring, progress bar, MultiSelect, column width/format, FastListViewHelper.
H1–H8 must PASS.

When sync + History checklists are PASS → **STOP** and ask before Live/Client cutover.

---

## UserRights / menu / report parity

Policy copied from SB:

| Item | Rule |
|------|------|
| Direction | **L2C only** (`CaptureLocal=1` Local, `CaptureCloud=0` both) |
| Entry Delete | `AllowDelete=1` only for admin UserIDs (SB: 1,2,3,4,5,8 — retarget for SB2) |
| Entry Edit | `AllowEdit=0` → readonly+Print; Save gated by LogDay/AllowBackDate when Edit=1 |
| Reports | Grant/clone scripts under `docs/sql/Grant_*` / `Clone_UserRights_*` |
| App code | Port `UserEntryRights` + form Save gates if SB2 WinForms fork diverged |

---

## File map to copy into SB2

Minimum copy set:

```text
SB.sln                            # Visual Studio: SB, SB.SyncAgent, SB.SyncStatus
SB.SyncAgent/          (or rename)
SB.SyncStatus/
SB/FastListViewHelper.cs          # recover if missing — required
SB/frm_Main.cs + .Designer.cs     # history bind, footer, progress, columns
SB/frm_List.cs (+ related list forms using helper)
lib/ObjectListView.dll            # SB.csproj HintPath is ..\lib\ObjectListView.dll
docs/sql/DataSync_01_Schema.sql
docs/sql/DataSync_04_SoftDelete_Migration.sql
docs/sql/DataSync_10_SyncApply_Generic.sql
docs/sql/DataSync_11_*.sql
docs/sql/DataSync_14_MasterPriority.sql
docs/sql/DataSync_15_ERPTransactionTables.sql
docs/sql/DataSync_28_EnableC2L_Capture.sql
docs/sql/DataSync_UserRights_L2C_Only.sql
docs/sql/DataSync_UserRights_L2C_Only_Local.sql
docs/sql/Deploy_TxnDetail_HardDeleteSync_*.sql
docs/sql/Deploy_EditDeleteSync_*.sql
docs/sql/Update_AllowDelete_AdminUsers_MenuID2.sql
docs/sql/Sales_Listview_NarrowCarDiscount.sql
docs/sql/README_UserEntryRights_Deploy.md
docs/SB2_PORT_PROMPT.md
docs/SB2_Agent_Prompt_Short.md
docs/SB2_Sync_Bootstrap_Playbook.md
docs/SB2_HistoryListView_Port.md
docs/SB2_DEV_TEST_RESULTS.template.md
docs/config/SB2_CONNECTIONS.template.md
docs/sql/SB2_Run_LocalBootstrap.ps1
docs/sql/SB2_Run_CloudAfterRestore.ps1
```

Optional later: C2L txn packs, ghost cleanups, purchase/sale diagnose scripts.

---

## Common mistakes

| Mistake | Result |
|---------|--------|
| Run Cloud C2L install on Local | Wrong-direction outbox / broken L2C |
| Skip Local-first restore | Cloud missing columns → apply failures |
| UserRights C2L left on | Rights fight / flicker |
| Detail apply without `@Operation` | Delete syncs as soft ghost |
| Wrong ini / RC4 key | Agent cannot open DB |
| Commit real passwords | Security incident |
| Skip `FastListViewHelper` / ObjectListView | History bind crashes or falls back to slow ListView |
| No status-strip Spring | Footer totals clipped off-screen |
| MultiSelect left false | Cannot multi-select history rows |
| Skip Sales ListviewItem width SQL | Charges/Amount columns crushed |

---

## After SB2 goes live

Do not fill live server names in this phase. Live/Client cutover is a separate task and is not approved.

1. After that cutover is approved, fill actual server names into an “as deployed” section.
2. Keep SB and SB2 script fixes in sync when fixing Detail/Head delete bugs.
3. Prefer shared `docs/sql` changes upstreamed to both repos.
