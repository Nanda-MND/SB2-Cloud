# Transaction sync — bidirectional (L2C + C2L)

Enable **Local↔Cloud** sync for all entry/transaction tables.

| Direction | Where to edit | Script |
|-----------|---------------|--------|
| **L2C** | Local ERP | `Fix_AllEntry_Local_L2C_Capture.sql` |
| **C2L** | Cloud ERP / SSMS | `Fix_AllTxn_Cloud_C2L_Capture.sql` |

## Order

### 1) LOCAL (SB1)

```text
docs/sql/Fix_AllEntry_Local_L2C_Capture.sql
```

Expect: `CaptureLocal=1`, `CaptureCloud=0`, triggers `tr_SyncOutbox_*`

### 2) CLOUD (site4now)

If never installed C2L helper:

```text
docs/sql/DataSync_28_EnableC2L_Capture.sql
```

Then:

```text
docs/sql/Fix_AllTxn_Cloud_C2L_Capture.sql
```

Expect: `CaptureCloud=1`, `CaptureLocal=0`, triggers present

### 3) SyncAgent

Keep agent running (L2C push + C2L pull).

## Verify

**Local — after Local edit:**

```sql
SELECT TOP 20 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'L2C' AND Status = N'Pending'
ORDER BY OutboxID DESC;
```

**Cloud — after Cloud edit:**

```sql
SELECT TOP 20 OutboxID, TableName, Status, PrimaryKeyJson, CreatedAt
FROM dbo.SyncOutbox
WHERE Direction = N'C2L' AND Status = N'Pending'
ORDER BY OutboxID DESC;
```

## Cloud Purchase not on Local

See `README_Purchase_C2L_NotLanding.md`  
(`Fix_PurchaseC2L_LocalWinsUnblock.sql` → `Fix_PurchaseC2L_CloudRetry.sql`).

## Config rules (do not mix)

| Side | CaptureLocal | CaptureCloud |
|------|--------------|--------------|
| Local | 1 | 0 |
| Cloud | 0 | 1 |

Never set `CaptureCloud=1` on Local (creates wrong C2L outbox on office DB).

## Tables covered

Sale / Purchase / Order / Return / Transfer / Adjustment / Stock receive /
Manufacture / IncomeExpense / Account+party Opening / Journal / CustSupTransfer  
(Missing tables are skipped automatically.)
