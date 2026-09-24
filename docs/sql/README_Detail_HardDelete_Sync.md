# Detail row delete does not disappear on the other side

## Cause

ERP UI **physical DELETE**s detail rows (`SqlDataAdapter.Update` on `DataRowState.Deleted`).
`SyncApply_Generic` used to **soft-delete** (`IsDeleted=1`) because the column exists.
UI SELECT has **no** `IsDeleted=0` filter → ghost line still shows after sync.

## Fix

`docs/sql/DataSync_10_SyncApply_Generic.sql` — tables named `*Detail` now **hard DELETE** on Operation `D`.
Head/master tables still soft-delete.

## Deploy (both Local SB1 + Cloud warehouse)

```text
git pull
docs/sql/DataSync_10_SyncApply_Generic.sql
```

## Re-sync old soft-deleted / ghost detail lines

```text
1) LOCAL SB1:  docs/sql/Fix_DetailHardDelete_ReSync.sql
2) CLOUD:      docs/sql/Fix_DetailHardDelete_ReSync.sql
3) Keep SyncAgent running
```

Script: checks SyncApply has `hardDeleteDetail`, physically removes `IsDeleted=1`
ghosts on this DB, and on Cloud requeues recent C2L `*Detail` Operation=`D`.

## Test (new deletes)

1. Edit Purchase → delete one detail line → Save  
2. Wait sync  
3. Other side: that line gone (not just IsDeleted=1)
