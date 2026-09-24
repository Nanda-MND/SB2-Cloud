# Purchase C2L still not on Local

## Current screenshot reading (2026-09-21)

Cloud: `AttemptCount=1`, mix **Synced** + **Conflict**. Agent IS pulling.  
Local SB1: only `2000000000`, `2000000001` — missing `2000000002+`.

→ Conflict = LocalWins (Err null on Cloud; see Local `SyncConflictLog`).  
→ Synced but missing on SB1 = wrong Local DB **or** need Synced→Pending retry after Local prep.

### Do this now

```text
LOCAL:  docs/sql/Fix_PurchaseC2L_LocalPrepForRequeue.sql
LOCAL:  docs/sql/DataSync_10_SyncApply_Generic.sql
CLOUD:  docs/sql/Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql
```

Restart SyncAgent → Local:

```sql
SELECT ID FROM PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;
```

Expect `2000000002`, `2000000003`, `2000000004`, …

If Cloud shows Synced again but Local still missing those IDs → **Agent `DBConnection.ini` is not SB1**.

## SyncModifiedAt မှားရင်?

| Side | SyncModifiedAt | Effect |
|------|----------------|--------|
| **Local** Aug 22 (after LocalWinsUnblock) | OK — intentionally old so Cloud wins |
| **Cloud** Aug 22 | BAD — Cloud older than Local → **LocalWins / Conflict** |

Cloud မှာ `SyncModifiedAt` က voucher `Date` ထက် ပိုဟောင်းနေရင်:

```text
docs/sql/Fix_PurchaseC2L_CloudBumpSyncModifiedAt.sql
```

ပြီး SyncAgent ပြန်ဖွင့်။

## Fast path (do in order)

### A) LOCAL (`SB1`)
```text
docs/sql/Diagnose_PurchaseC2L_Local.sql
docs/sql/Fix_PurchaseC2L_LocalAfterWrongCloudRun.sql   -- if CaptureCloud was 1
docs/sql/Fix_PurchaseC2L_LocalWinsUnblock.sql
docs/sql/DataSync_10_SyncApply_Generic.sql
```

### B) CLOUD (`db_*warehouse`)
```text
docs/sql/Diagnose_PurchaseC2L_Cloud.sql
docs/sql/Fix_PurchaseC2L_CloudResetPending.sql
```

### C) SyncAgent
Restart SyncAgent. Wait 30–60 seconds.

### D) CLOUD — re-check
```sql
SELECT Status, AttemptCount, PrimaryKeyJson, LEFT(LastError,80) Err
FROM SyncOutbox
WHERE Direction=N'C2L' AND TableName LIKE N'Purchase%'
ORDER BY OutboxID DESC;
```

| Result | Meaning |
|--------|---------|
| Pending, AttemptCount stays **0** | **Agent not pulling** this Cloud DB — check Agent + CloudConnection.ini |
| Conflict + LocalWins | Local unblock again, then CloudResetPending |
| Synced | Check Local IDs |

### E) LOCAL verify
```sql
SELECT ID, Deleted, SyncOrigin FROM PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;
```

---

## Agent still dead / emergency land (no Agent)

1. CLOUD: `Generate_PurchaseC2L_ApplyOnLocal.sql` (Results to Text)
2. Copy each `SqlBatch` → run on LOCAL (Head first, then Detail)
3. Verify Local IDs

---

## Config reminder

| Side | CaptureLocal | CaptureCloud |
|------|--------------|--------------|
| Local | 1 | **0** |
| Cloud | 0 | **1** |
