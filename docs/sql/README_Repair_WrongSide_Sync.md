# DB sync — မှား run မိရင် ပြန် fix

## စည်းကမ်း (မှတ်ထား)

| DB | Script | ရလဒ် |
|----|--------|------|
| **Local SB1** | `Fix_AllEntry_Local_L2C_Capture.sql` | CaptureLocal=1, CaptureCloud=0 |
| **Cloud** | `Fix_AllTxn_Cloud_C2L_Capture.sql` | CaptureCloud=1, CaptureLocal=0 |

Local မှာ Cloud script မrunရ။ Cloud မှာ Local script မrunရ။

---

## Case A — Local မှာ Cloud script run မိ

**Local SB1** SSMS:

```text
docs/sql/Repair_Local_AfterWrongCloudScript.sql
```

ပြီး (အကြံ):

```text
docs/sql/Fix_AllEntry_Local_L2C_Capture.sql
```

စစ်:

```sql
SELECT TableName, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName LIKE N'%Head' OR TableName LIKE N'%Detail'
ORDER BY TableName;

-- Local မှာ CaptureCloud = 0, CaptureLocal = 1 ဖြစ်ရမယ်
-- SyncOutbox မှာ Direction=C2L မရှိသင့် (သို့ Pending မရှိ)
```

---

## Case B — Cloud မှာ Local script run မိ / C2L ပျက်

**Cloud** SSMS (အရင် helper မရှိရင်):

```text
docs/sql/DataSync_28_EnableC2L_Capture.sql
```

ပြီး:

```text
docs/sql/Fix_AllTxn_Cloud_C2L_Capture.sql
```

စစ်:

```sql
SELECT TableName, CaptureLocal, CaptureCloud
FROM dbo.SyncConfig
WHERE TableName IN (N'SaleHead', N'TransferHead', N'PurchaseHead');
-- CaptureCloud=1, CaptureLocal=0
```

---

## Case C — နှစ်ဖက်လုံး ပြန်သေချာချင်

1. Local → `Repair_Local_AfterWrongCloudScript.sql` ပြီး `Fix_AllEntry_Local_L2C_Capture.sql`  
2. Cloud → `Fix_AllTxn_Cloud_C2L_Capture.sql`  
3. SyncAgent restart / running  
4. Entry တစ်ခု Local Save → Cloud စစ်၊ Cloud ပြင် → Local စစ်

---

## Pull

```powershell
cd D:\Project\SB
git pull origin cursor/cheque-print-and-balance-filters
```
