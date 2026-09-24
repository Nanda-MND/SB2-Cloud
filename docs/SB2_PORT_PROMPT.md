# SB2-Cloud Sync Port — Cursor Agent Prompt

Use this in a **new GitHub repo named `SB2-Cloud`**.  
Do **not** apply these changes inside the live **SB** production repo.

**First milestone = Dev PC + Test Cloud only.**  
Live DB / Client PC are out of scope until Dev acceptance is green.

Copy everything below the line into a new Cursor Agent chat **inside the SB2-Cloud workspace**.

---

## PROMPT START

```text
You are building sync for a NEW repository named **SB2-Cloud**.

## Repo / environment lock (read first)
1. Work ONLY in this SB2-Cloud repo. Do not commit to or alter the live SB production repo.
2. Source reference: copy proven files FROM the SB repo (read-only reference), then adapt here.
3. TEST ENVIRONMENT ONLY for this entire task:
   - Allowed: Dev PC Local SQL Server + Test Cloud SQL
   - Forbidden until explicit approval: Live/production databases, Client PC installs,
     live SyncAgent Windows service on customer machines
4. Connection strings must be DEV/TEST only. Store in docs/config/SB2_CONNECTIONS.md
   (no production passwords; never commit secrets).
5. When Dev↔Test Cloud acceptance passes, STOP and ask for a separate Live/Client cutover plan.
   Do not “helpfully” deploy to live.

## Goal
Bring SB2-Cloud to the same L2C / C2L sync pattern as SB, **plus** the Main history ListView UX pack:
- Local SQL (Dev) = primary
- Test Cloud SQL = secondary
- Windows service SyncAgent pushes L2C and pulls C2L (install on Dev PC only in this phase)
- Tray app (SyncStatus) shows pending/error health (Dev PC)
- UserRights / menu / report rights behave like SB (UserRights = L2C-only)
- Detail hard-delete sync + Head soft-delete sync where SB already fixed it
- History ListView: footer summary, load progress bar, MultiSelect, column width/format
  (see docs/SB2_HistoryListView_Port.md)

## Non-negotiable deploy order

### Phase 0 — Inputs (DEV/TEST only)
Ask once, write docs/config/SB2_CONNECTIONS.md:

| Key | Must be |
|-----|---------|
| LocalServer / LocalDatabase | Dev PC SQL (NOT live) |
| CloudServer / CloudDatabase | Test Cloud (NOT production cloud) |
| ErpInstallPath | Dev PC ERP/test folder (NOT client PC path) |
| WindowsServiceName | e.g. SB2.SyncAgent.Dev |
| Environment | `DEV_TEST` |

Also confirm RC4 encrypt key matches SB2 WinForms (SB reference: `27042005`).

Reject / refuse if user pastes live/client connection strings for this phase —
ask them to provide Dev/Test endpoints instead.

### Phase 1 — DEV LOCAL FIRST
1. Backup Dev Local DB.
2. Ensure projects exist (copy from SB reference if missing):
   - SyncAgent (Windows service)
   - SyncStatus (tray)
3. On DEV LOCAL run (or docs/sql/SB2_Run_LocalBootstrap.ps1 with Dev params):
   1. DataSync_01_Schema.sql
   2. DataSync_04_SoftDelete_Migration.sql
   3. DataSync_10_SyncApply_Generic.sql  (must contain hardDeleteDetail)
   4. DataSync_03_ApplyInbound.sql (if required)
   5. DataSync_11_AllTables_Install.sql + DataSync_11_RunLocal.sql (InstallCapture=1)
   6. DataSync_14_MasterPriority.sql
   7. DataSync_15_ERPTransactionTables.sql (if used)
   8. Deploy_TxnDetail_HardDeleteSync_LOCAL.sql
   9. Deploy_EditDeleteSync_LOCAL.sql
   10. UserRights Local pack:
       - Update_AllowDelete_AdminUsers_MenuID2.sql (adjust UserIDs for SB2)
       - DataSync_UserRights_L2C_Only_Local.sql
       - Grant/Clone report rights scripts as needed
       - Fix_Duplicate_UserRights_BothSides.sql if needed
4. Verify on Dev Local: SyncConfig OK; ERP edit → SyncOutbox L2C Pending;
   SyncApply_Generic has hardDeleteDetail.

### Phase 2 — CREATE TEST CLOUD FROM DEV LOCAL BACKUP
1. Fresh Dev Local .bak AFTER Phase 1 succeeds.
2. Restore that .bak onto **Test Cloud** only (never production cloud).
3. Do not blindly re-run Local capture install on Cloud.
4. Smoke: DB_NAME(), SyncConfig exists.

### Phase 3 — TEST CLOUD-ONLY scripts
On TEST CLOUD:
1. Re-apply DataSync_10_SyncApply_Generic.sql if needed
2. DataSync_28_EnableC2L_Capture.sql
3. CaptureCloud=1 / CaptureLocal=0 only for tables that may be cloud-edited
4. Deploy_TxnDetail_HardDeleteSync_CLOUD.sql
5. Deploy_EditDeleteSync_CLOUD.sql
6. DataSync_UserRights_L2C_Only.sql (CaptureCloud=0; drop UserRights C2L triggers)
7. Optional txn C2L packs (Sale/Purchase/Transfer) only if product needs them on SB2

### Phase 4 — Dev PC binaries only
1. Build Release SyncAgent + SyncStatus into Dev ERP/test folder.
2. Encrypt next to agent:
   - DBConnection.ini → Dev Local
   - CloudConnection.ini → Test Cloud
3. SyncAgent.exe /once (or /test). Fix failures before service install.
4. Optional on Dev: install Windows service with a Dev-specific name.
5. Start tray on Dev. Confirm Pending drains Dev↔Test Cloud.

### Phase 4b — History ListView UX (Dev PC app — required)
Follow docs/SB2_HistoryListView_Port.md in full. Port from SB:
1. FastListViewHelper.cs (recover/commit if missing in reference clone) + ObjectListView.dll reference
2. frm_Main history bind/configure + Designer status strip:
   - Footer summary labels (Total / Paid / PK / Bank Charges / Income-Expense as needed)
   - Spring spacer so totals stay visible
   - tspbHistoryLoad progress during FillListView
3. MultiSelect = true on history list; selection helpers safe for 0/1/N rows
4. Column width/format:
   - ListviewItem-driven columns
   - Sales Charges column + narrow Car/Discount/Charges/Paid/PK
   - Run docs/sql/Sales_Listview_NarrowCarDiscount.sql on Dev Local (and Test Cloud if needed)
   - Cashbook + Balance list defaults
5. Do not regress filter ComboBox DropDown typing or menu-switch performance
6. Verify H1–H8 on Dev PC before calling Phase 5 done

### Phase 5 — Dev/Test acceptance (write docs/SB2_DEV_TEST_RESULTS.md)
1. Dev Local master edit → appears on Test Cloud
2. If C2L on: Test Cloud edit → appears on Dev Local
3. Delete one detail line on Dev → Test Cloud line gone (hard delete)
4. Soft-delete a Head on Dev → Test Cloud stays deleted
5. UserRights change on Dev → Test Cloud follows; Cloud must not overwrite Local
6. Offline Dev ERP works; outbox drains when online
7. History ListView H1–H8 all PASS (footer, progress, multiselect, column widths/formats)

After Phase 5 is green: STOP.
Ask before any Live DB / Client PC cutover document or deploy.

## Rules
- Prefer copying proven docs/sql/* from SB into SB2-Cloud; adapt DB-name guards for Dev/Test names.
- Split LOCAL vs CLOUD scripts with wrong-DB RAISERROR guards.
- Never CaptureLocal=1 on Cloud or CaptureCloud=1 on Local for the same table without explicit dual-write design.
- UserRights = L2C only.
- Detail Op=D = hard delete; Head Op=D = soft delete.
- Do not invent a new sync schema; reuse SyncConfig / SyncOutbox / SyncApply_Generic.
- Never commit real passwords or encrypted ini with secrets.
- Never target live/client in this task.

## Deliverables in SB2-Cloud repo
1. docs/config/SB2_CONNECTIONS.md (DEV/TEST placeholders only)
2. Ported SQL under docs/sql/ with Dev/Test DB guards
3. SyncAgent + SyncStatus projects building
4. History ListView UX ported (FastListViewHelper + Main footer/progress/multiselect/columns)
5. docs/SB2_Sync_Bootstrap_Playbook.md filled with Dev/Test names
6. docs/SB2_DEV_TEST_RESULTS.md with sync + History H1–H8 checkboxes
7. Explicit note: Live/Client cutover = future task only

Start by: inventory this SB2-Cloud repo; copy missing Sync* projects/scripts and
FastListViewHelper / history ListView pieces from SB reference;
confirm connections are Dev/Test; then Phase 0→1.
```

## PROMPT END

---

See also:
- [`SB2_Agent_Prompt_Short.md`](SB2_Agent_Prompt_Short.md)
- [`SB2_Sync_Bootstrap_Playbook.md`](SB2_Sync_Bootstrap_Playbook.md)
- [`SB2_HistoryListView_Port.md`](SB2_HistoryListView_Port.md)
- [`config/SB2_CONNECTIONS.template.md`](config/SB2_CONNECTIONS.template.md)
