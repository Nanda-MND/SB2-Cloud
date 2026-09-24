# User 14 / 16 — SQL run packs (Entry-Edit disable မှစ)

Idempotent packs။ ထပ် run လို့ရ (`0 rows` / already-done = OK၊ error မတက်အောင် စီမံထား)။

## Pull

```bash
git pull origin cursor/cheque-print-and-balance-filters
```

## Run order

| # | Where | File |
|---|--------|------|
| 1 | **Local SB1** | `docs/sql/RunPack_Users14_16_Local.sql` |
| 2 | **Cloud** | `docs/sql/RunPack_Users14_16_Cloud.sql` |

## Pack အတွင်းပါတာ

### Local — `RunPack_Users14_16_Local.sql`

1. Entry Edit ပိတ် — User 14/16 (`MenuID=2`, `AllowEdit=0`)
2. `UserRights` SyncConfig → L2C only (`CaptureLocal=1`, `CaptureCloud=0`)
3. Deduplicate `UserRights` `(UserID, MenuID, MenuSubID)`

### Cloud — `RunPack_Users14_16_Cloud.sql`

1. Entry Edit ပိတ် — User 14/16 (Local နဲ့ တူအောင်)
2. `LogInClient.ID=14` → active user အားလုံး `isAllow=1`
3. `UserRights` SyncConfig → L2C apply only (`CaptureCloud=0`, C2L trigger drop)
4. Deduplicate `UserRights`

## Edit-disable မတိုင်ခင် run ပြီးသား (pack ထဲမထည့်)

| Script | Purpose |
|--------|---------|
| `Clone_UserRights_14_to_16.sql` | Rights 14→16 clone |
| `Restrict_LogInClient_client1_Users14_16.sql` | client-1 = 14+16 only |
| `Restrict_User14_Reports_StockBalanceOnly.sql` | User 14 reports lockdown + 1079 |
| `Grant_UserRights_StockIssueByInvoice_14_16.sql` | Report 1079 → 14/16 |

DB တစ်ခုက မရောက်သေးမှသာ ထပ် run။

## တစ်ခုချင်း (pack နဲ့အတူတူ)

| Step | Local | Cloud |
|------|-------|-------|
| Edit off | `Disable_EntryEdit_Users14_16.sql` | same |
| LogInClient 14 all users | — | `AllowAllUsers_LogInClient_ID14.sql` |
| L2C-only | `DataSync_UserRights_L2C_Only_Local.sql` | `DataSync_UserRights_L2C_Only.sql` |
| Dedup | `Fix_Duplicate_UserRights_BothSides.sql` | same |
