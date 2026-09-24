# Step-by-step Purchase C2L

## Step 1 — Cloud ✅ done

Cloud healthy: CaptureCloud=1, Agent pulls (`Synced` + `Conflict`), Heads `0..4` present.

## Step 2 — Local ✅ done (SB1)

| Check | Result |
|-------|--------|
| SyncConfig | CaptureLocal=1, CaptureCloud=0 OK |
| Heads | `0`,`1` PRESENT; **`2`,`3`,`4` MISSING_ON_LOCAL** |
| BlockingL2C | 0 |
| SyncConflictLog | `LocalWinsSkipped` on `0`/`1` (“Local … is newer”) |
| ApplyVer | May show false OK — Conflict text is **old** LocalWins |

**Verdict:** Local apply / LocalWins — not Cloud capture. Redeploy SyncApply + age Local clocks + Cloud requeue.

---

## Step 3 — Fix (run in order)

### 3.0 LOCAL — redeploy SyncApply (required)

```text
docs/sql/DataSync_10_SyncApply_Generic.sql
```

Must contain `isCloudZonePk` (cloud-zone IDs bypass timestamp LocalWins).

### 3.1 LOCAL — prep clocks / config

```text
docs/sql/Step3a_Local_PurchaseC2L_Prep.sql
```

Stops if SyncApply still lacks `isCloudZonePk`.

### 3.2 CLOUD — requeue Synced + Conflict

```text
docs/sql/Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql
```

Keep SyncAgent running.

### 3.3 LOCAL — verify

```sql
SELECT ID, SyncOrigin, SyncModifiedAt
FROM dbo.PurchaseHead
WHERE ID >= 2000000000
ORDER BY ID;
-- expect 2000000000 .. 2000000004
```

### 3.4 If still only `0`/`1` (Agent updated those; `2..4` missing)

Cloud already proved Agent writes SB1 (`SyncModifiedAt` matched requeue). Run:

```text
docs/sql/Step3b_Cloud_MissingPurchaseHeads.sql
```

Restart SyncAgent → wait Pending→Synced → re-verify Local.

If Cloud shows **Synced** for `2..4` but Local still missing:

```text
docs/sql/Generate_PurchaseC2L_ApplyOnLocal.sql
```

Paste `SqlBatch` (Heads first, then Details) onto LOCAL.
