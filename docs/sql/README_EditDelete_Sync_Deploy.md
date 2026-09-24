# Head / Detail edit-delete sync — deploy pack

Partial runs caused errors before. Follow **this order only**. Do not skip Step 1.

Scripts are **Local vs Cloud split**, with guards so incomplete `DataSync_10` cannot cascade into later steps.

---

## What this fixes

| Issue | Fix |
|-------|-----|
| Detail row delete stays on other side | `*Detail` Operation `D` → **hard DELETE** |
| Head soft-delete undone later | UPDATE **preserves** `Deleted` / `IsDeleted` |
| Head `D` ignored via wrapper | `SyncApply_PurchaseHead` passes `@Operation` |

---

## Safety (partial / unfinished deploy)

| Guard | Behavior |
|-------|----------|
| Wrong DB | LOCAL refuses `*warehouse*`; CLOUD refuses `SB1`/`SB` |
| Missing / old `SyncApply_Generic` | STOP + `SET NOEXEC` — steps 1–4 skipped |
| Optional columns / tables | SKIP + PRINT (no abort) |
| Ghost cleanup / requeue | TRY/CATCH per table / block |

---

## Order (do not reverse)

### Step 1 — BOTH Local SB1 **and** Cloud warehouse

```text
docs/sql/DataSync_10_SyncApply_Generic.sql
```

Must succeed on **both** DBs before Step 2/3.

Check:
```sql
SELECT
  CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) LIKE N'%hardDeleteDetail%'
       THEN N'OK' ELSE N'MISSING hardDeleteDetail' END AS DetailHardDelete,
  CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.SyncApply_Generic')) LIKE N'%preserve-soft-delete-flags%'
       THEN N'OK' ELSE N'MISSING preserve-soft-delete-flags' END AS HeadSoftDelete;
-- both OK required
```

### Step 2 — LOCAL only (SB1)

```text
docs/sql/Deploy_EditDeleteSync_LOCAL.sql
```

Does: Purchase Apply wrappers → Detail ghost hard-delete → Head Deleted→IsDeleted mirror → **L2C** requeue Op=D

### Step 3 — CLOUD only (`*warehouse`)

```text
docs/sql/Deploy_EditDeleteSync_CLOUD.sql
```

Does: same wrappers/cleanup/mirror → **C2L** requeue Op=D

### Step 4 — Client PC (SyncAgent)

```text
git pull
cd SB.SyncAgent
.\Build-SyncAgent.cmd
```

Copy `bin\Release\SB.SyncAgent.exe` → ERP folder → `net stop SB.SyncAgent` → replace → `net start SB.SyncAgent`

### Step 5 — Verify

```sql
-- Soft-deleted heads
SELECT ID, Deleted, IsDeleted FROM dbo.PurchaseHead
WHERE ISNULL(Deleted,0)<>0 OR ISNULL(IsDeleted,0)<>0;

-- Detail ghosts should be 0
SELECT COUNT(*) FROM dbo.PurchaseDetail WHERE ISNULL(IsDeleted,0)=1;
```

---

## If Step 2/3 stop with STOP / SKIP remaining

`DataSync_10` not deployed (or old) on that DB. Re-run **Step 1** on that side, then retry Step 2 or 3.

---

## Do NOT

- Run LOCAL script on Cloud (or reverse)
- Run re-sync scripts before `DataSync_10`
- Mix half of Detail pack + half of Head pack without Step 1
