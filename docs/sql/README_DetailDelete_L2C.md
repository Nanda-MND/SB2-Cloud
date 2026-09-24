# Detail DELETE → L2C မရောက် (Cloud မှာလိုင်းကျန်)

## Symptom

Cloud new → C2L OK · Local head edit + detail insert → L2C OK · **detail delete → Cloud မှာလိုင်းကျန်**

## Cause

ERP physical DELETE → outbox `Operation=D` → Cloud `SyncApply_Generic` must **hard DELETE**.  
Old apply = `IsDeleted=1` ghost (UI filter မရှိ)။ Wrapper မှာ `@Operation` မရှိရင် Agent `D` မပို့နိုင်။

## Fix order

```text
git pull

# BOTH Local + Cloud
docs/sql/DataSync_10_SyncApply_Generic.sql
docs/sql/Fix_DetailDelete_Sync_BothSides.sql

# LOCAL only — restore DELETE→Op=D capture
docs/sql/DataSync_06_Purchase.sql
```

SyncAgent run ထား။

## Test

Local Purchase → detail တစ်ကြောင်းဖျက် → Save → Cloud မှာလိုင်း **ပျောက်** ရမယ်။

## Diagnose (optional)

```text
LOCAL: docs/sql/Diagnose_DetailDelete_L2C_Local.sql
CLOUD: docs/sql/Diagnose_DetailDelete_L2C_Cloud.sql
```
