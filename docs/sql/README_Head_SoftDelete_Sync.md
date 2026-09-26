# Head soft-delete does not sync

## Cause

1. ERP sets `PurchaseHead.Deleted = 1` (soft delete).
2. Sync enqueues Operation `D` / payload with `Deleted=1`.
3. **Bug:** `SyncApply_Generic` UPDATE always forced `Deleted=0` and `IsDeleted=0`.
   A later `U` row undid the soft-delete on the other side.

## Fix

- `DataSync_10_SyncApply_Generic.sql` — UPDATE preserves `Deleted` / `IsDeleted` from JSON
- `DataSync_06_Purchase.sql` — `SyncApply_PurchaseHead` passes `@Operation`
- `SB.SyncAgent` — pass `@Operation` for Head applies
- `DataSync_11_AllTables_Install.sql` and `DataSync_28_EnableC2L_Capture.sql` — `Deleted=0→1` enqueues Op=D on both sides. The metadata trigger must not replace that with Op=U. `tr_*_SoftDeleteSync` sets source `IsDeleted=1` and `DeletedAt` (marker `headSoftDeleteIsDeleted`).
- `SB.SyncAgent` — C2L Detail Op=D treats a missing target row as success. Head Op=D must still find the row.

## Deploy

```text
git pull

# BOTH Local + Cloud
docs/sql/DataSync_10_SyncApply_Generic.sql
docs/sql/DataSync_06_Purchase.sql          # optional but recommended

# LOCAL then CLOUD — requeue soft-deletes
docs/sql/Fix_HeadSoftDelete_ReSync.sql

# Client PC — rebuild SyncAgent + restart service
cd SB.SyncAgent
.\Build-SyncAgent.cmd
# copy exe → ERP folder, net stop/start SB.SyncAgent
```

## Verify

```sql
-- Side where you deleted:
SELECT ID, Deleted, IsDeleted FROM dbo.PurchaseHead WHERE ISNULL(Deleted,0)<>0;

-- Other side after sync:
SELECT ID, Deleted, IsDeleted FROM dbo.PurchaseHead WHERE ID IN (...);
-- expect Deleted=1 (row hidden in ERP list)
```
