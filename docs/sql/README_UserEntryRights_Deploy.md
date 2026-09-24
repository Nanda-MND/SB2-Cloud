# UserEntryRights deploy

## Rules (agreed)

| Flag | Behavior |
|------|----------|
| `AllowTransaction` | New (submenu visibility — unchanged) |
| `AllowDelete = 1` | Show Delete on history context menu |
| `AllowEdit = 0` | Edit opens form readonly + Print only; Save blocked |
| `AllowEdit = 1` | Save only if `LogDay` + `AllowBackDate` OK |
| Date gates | All Entry `MenuID = 2` forms |

## SQL (run Local, then Cloud if needed)

1. `Update_AllowDelete_AdminUsers_MenuID2.sql` — UserID **1,2,3,4,5,8** → `AllowDelete=1`; all other users → `AllowDelete=0` on MenuID=2  
2. Optional: `Check_Users_AllowBackDate_Off.sql` — list users blocked from back-date Save

## App

Rebuild/deploy `SB` with `UserEntryRights.cs` + Main/entry form Save gates.

Re-login after SQL + deploy.
