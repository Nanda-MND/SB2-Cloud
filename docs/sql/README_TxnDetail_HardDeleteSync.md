# Transaction Detail hard-delete sync (all txn)

ERP UI **physical DELETE**s detail rows. Sync must:

1. Capture `Operation=D` on the source DB  
2. Agent passes `@Operation=D`  
3. `SyncApply_Generic` **hard DELETE**s `*Detail` on the target (`hardDeleteDetail`)

## Deploy order

```text
git pull

# BOTH sides first (if not already)
docs/sql/DataSync_10_SyncApply_Generic.sql

# LOCAL (needs SyncInstall_Table from DataSync_11)
docs/sql/DataSync_11_AllTables_Install.sql          # once if SyncInstall_Table missing
docs/sql/Deploy_TxnDetail_HardDeleteSync_LOCAL.sql

# CLOUD (needs SyncInstall_CloudCapture from DataSync_28)
docs/sql/DataSync_28_EnableC2L_Capture.sql          # once if SyncInstall_CloudCapture missing
docs/sql/Deploy_TxnDetail_HardDeleteSync_CLOUD.sql

# Client
rebuild SyncAgent + restart
```

## What the deploy scripts do

| Side | Capture | Apply wrappers | Ghosts | Requeue |
|------|---------|----------------|--------|---------|
| **LOCAL** | `CaptureLocal=1`, DELETE→L2C Op=D | `SyncApply_*Detail` +`@Operation` | hard-delete `IsDeleted=1` | L2C Op=D 7d |
| **CLOUD** | `CaptureCloud=1`, DELETE→C2L Op=D | same | same | C2L Op=D 7d |

Covers known txn `*Detail` (Sale/Purchase/Transfer/Manufacture/Stock/Opening/Journal/…) plus any other `*Detail` with `ID`+`RefID`.

## Verify

Each script prints `CaptureOK` / `TriggerOK` / `ApplyOK`. **`BadCount` must be 0.**

## Test

1. Local: delete one Transfer/Purchase detail → Save → Cloud line **gone**  
2. Cloud: same → Local line **gone**

## Old ghosts (last 2 days)

```text
docs/sql/Cleanup_DetailDeleteGhosts_2Days_LOCAL.sql
docs/sql/Cleanup_DetailDeleteGhosts_2Days_CLOUD.sql
```
