# Cleanup Detail hard-delete sync ghosts (last 2 days)

Detail DELETE sync error ကြောင့် Local/Cloud မှာ ကျန်တဲ့ row ရှင်းရန်။

## Order

```text
git pull

# 1) LOCAL SB1
docs/sql/Cleanup_DetailDeleteGhosts_2Days_LOCAL.sql

# 2) CLOUD warehouse
docs/sql/Cleanup_DetailDeleteGhosts_2Days_CLOUD.sql

# 3) LOCAL result grid "SqlBatch" ကို Cloud မှာ paste run
#    (L2C Op=D IDs that may still exist on Cloud)

# 4) SyncAgent running
```

## What each script does

| Script | Actions |
|--------|---------|
| LOCAL | Hard-delete `IsDeleted=1` ghosts · list L2C Op=D · **generate Cloud DELETE SqlBatch** · requeue Op=D |
| CLOUD | Hard-delete `IsDeleted=1` · delete by C2L Op=D IDs · known orphans (20384/85, 64191/76) · `@Operation` wrappers · requeue |

Window = **last 2 days UTC** (`DATEADD(day,-2,SYSUTCDATETIME())`).

## Verify

```sql
-- both sides
SELECT COUNT(*) FROM dbo.PurchaseDetail WHERE ISNULL(IsDeleted,0)=1;
SELECT COUNT(*) FROM dbo.TransferDetail WHERE ISNULL(IsDeleted,0)=1;

-- Cloud sample
SELECT ID, Remark FROM dbo.TransferDetail WHERE RefID = 2000000015;
SELECT ID, Remark FROM dbo.PurchaseDetail WHERE RefID = 2000000006;
```
