# Purchase C2L — worked yesterday, broken today

မနေ့ ရပြီး ဒီနေ့ မရောက် = အရင်ကလို **Local apply / LocalWins** သို့မဟုတ် **Cloud capture ပိတ်**။  
Requeue ကို မျက်စိမှိတ် မလုပ်ပါ။ **Step 1 → 2** ရလဒ်အရ Step 3။

---

## Order (do not skip)

### Step 1 — CLOUD diagnose

```text
docs/sql/Step1_Cloud_PurchaseC2L_Diagnose.sql
```

**GREEN လိုအပ်:**
| Check | Need |
|-------|------|
| SyncConfig Purchase* | `CaptureCloud=1`, `CaptureLocal=0`, `IsEnabled=1` |
| Triggers | write `C2L`, check `CaptureCloud` |
| Outbox | C2L rows exist; Agent pulls → `Synced` / `Conflict` with `AttemptCount>0` |
| Heads | cloud-zone IDs (`>= 2000000000`) present |

**RED → Cloud fix only (Local မလုပ်သေး):**
```text
docs/sql/DataSync_28_EnableC2L_Capture.sql
docs/sql/Fix_AllTxn_Cloud_C2L_Capture.sql   -- or DataSync_36_EnableC2L_Purchase.sql
```
SyncAgent running? `net start SB.SyncAgent` → `SB.SyncAgent.exe /test`

---

### Step 2 — LOCAL diagnose (Cloud GREEN ပြီးမှ)

```text
docs/sql/Step2_Local_PurchaseC2L_Diagnose.sql
```

| Result | Meaning |
|--------|---------|
| `HAS_CLOUDZONE_BYPASS` | SyncApply OK |
| `OLD_OR_UNKNOWN` / missing | Run `DataSync_10` on Local |
| Heads `MISSING_ON_LOCAL` | Local not landing |
| ConflictLog `LocalWinsSkipped` | clocks / bypass — Step 3 |
| `CaptureCloud=1` on Local | WRONG — fix Local config in Step 3a |

---

### Step 3 — Fix (LocalWins / missing on Local)

```text
# LOCAL
docs/sql/DataSync_10_SyncApply_Generic.sql
docs/sql/Step3a_Local_PurchaseC2L_Prep.sql

# CLOUD
docs/sql/Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql
```

Keep SyncAgent running. Wait Pending → Synced.

### Verify Local

```sql
SELECT ID, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID;
```

### Still missing some IDs (Agent Synced but row gone)

```text
docs/sql/Step3b_Cloud_MissingPurchaseHeads.sql
```

Then if still Synced-but-missing:

```text
docs/sql/Generate_PurchaseC2L_ApplyOnLocal.sql
```
→ paste `SqlBatch` onto **LOCAL**.

---

## Do NOT

- Run Cloud capture scripts on Local
- Requeue Cloud before Local has `isCloudZonePk` SyncApply
- Mix EditDelete Op=D pack with this unless Step 1/2 already GREEN

## After SyncAgent rebuild today

```text
net start SB.SyncAgent
SB.SyncAgent.exe /test
```

Cloud outbox `AttemptCount` must increase within ~1–2 min. 0 = Agent not pulling that Cloud DB.
