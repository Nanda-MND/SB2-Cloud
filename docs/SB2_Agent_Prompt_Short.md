# SB2-Cloud agent one-shot prompt (short)

**Repo:** create/open **`SB2-Cloud`** (new repo — do **not** change the live SB repo).  
**Environment:** **Dev PC Local + Test Cloud only** first. Never touch Live DB or Client PC until Dev tests pass.

Paste into the **SB2-Cloud** Cursor chat:

```text
Work ONLY in this new repo named SB2-Cloud. Do NOT modify the live SB production repo.

Port SB L2C/C2L sync into SB2-Cloud using the SB reference docs/scripts as a COPY source:
Follow docs/SB2_PORT_PROMPT.md and docs/SB2_Sync_Bootstrap_Playbook.md (copied into this repo).
Also follow docs/SB2_HistoryListView_Port.md for Main history ListView UX.

ENVIRONMENT LOCK (mandatory until you say otherwise):
- Allowed: Dev PC Local SQL + Test Cloud SQL only
- Forbidden: Live/production DB, Client PC ERP folder, live SyncAgent service
- All connection strings = DEV/TEST placeholders in docs/config/SB2_CONNECTIONS.md
- Do not encrypt or install Agent against live/client endpoints in this phase

Order is mandatory:
1) Collect DEV Local + TEST Cloud connection placeholders → docs/config/SB2_CONNECTIONS.md
2) On DEV Local: bootstrap SQL (DataSync 01→11 Local capture, Detail/Head delete packs, UserRights L2C-only Local)
3) Backup DEV Local → restore that .bak as TEST Cloud DB
4) On TEST Cloud: Cloud-only SQL (DataSync_28 C2L, Detail/Head CLOUD packs, UserRights L2C-only Cloud)
5) On DEV PC only: build SyncAgent + SyncStatus; encrypt DBConnection.ini / CloudConnection.ini for DEV/TEST; run /once (service install optional on Dev)
6) Port History ListView UX from SB (docs/SB2_HistoryListView_Port.md): footer summary + Spring, progress bar, MultiSelect, column width/format (Sales Charges + narrow cols, cashbook/balance defaults), FastListViewHelper + ObjectListView — recover helper .cs if missing
7) Run acceptance on Dev↔Test Cloud + History H1–H8; write docs/SB2_DEV_TEST_RESULTS.md

Do not reuse live SB1 / production cloud connection strings.
Keep UserRights L2C-only. Detail Op=D = hard delete.
After Dev/Test is green, STOP and ask before any Live/Client cutover plan.
```
