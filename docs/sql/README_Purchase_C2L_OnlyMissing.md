# Purchase C2L only missing (L2C OK)

## SyncAgent ကြောင့်လား?

**Connection မဟုတ်** — L2C အကုန်ရောက်ရင် Agent ↔ Local/Cloud OK။

Purchase C2L ပဲ မရောက်တာ ပုံမှန်အားဖြင့်:

1. **LocalWinsSkipped (Conflict)** — Local `SyncModifiedAt` ပိုအသစ် / Pending L2C ရှိ → Agent ဆွဲပြီး **skip** (Conflict). Agent ပျက်တာ မဟုတ်။
2. Cloud screenshot မှာ `Conflict` + `Err` null — အကြောင်းရင်း Local `SyncConflictLog` မှာ ရှိတယ်။

## ပြင်ရန် (အခု)

### 1) LOCAL — SyncApply အသစ် (cloud-zone ID က LocalWins မပိတ်တော့)

```text
docs/sql/DataSync_10_SyncApply_Generic.sql
docs/sql/Fix_PurchaseC2L_LocalPrepForRequeue.sql
```

`DataSync_10` အပြောင်းအလဲ: `ID >= 2000000000` (Cloud zone) အတွက် timestamp LocalWins **မလုပ်တော့** (Pending L2C ရှိမှပဲ skip)။

### 2) CLOUD — ပြန် Pending

```text
docs/sql/Fix_PurchaseC2L_CloudRequeueSyncedAndConflict.sql
```

### 3) SyncAgent restart (optional build with Conflict LastError)

### 4) LOCAL စစ်

```sql
SELECT ID FROM PurchaseHead WHERE ID >= 2000000000 ORDER BY ID;

SELECT TOP 20 Message, Resolution, PrimaryKeyJson, DetectedAt
FROM SyncConflictLog
WHERE TableName LIKE N'Purchase%'
ORDER BY ConflictID DESC;
```

## SyncAgent.log

Agent folder မှာ `SyncAgent.log` ဖွင့်ကြည့် — `C2L conflict` / `Pull failed` ရှိရင် Message က အကြောင်းရင်း။
