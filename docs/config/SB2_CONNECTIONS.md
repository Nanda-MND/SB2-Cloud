# SB2-Cloud connections — this test run

Environment flag: `DEV_TEST`

These are the databases for the current test run.  
When the live database is approved, change this file. Do not point this test run at live.

Passwords are not stored here and must not be committed.  
Set them only in the shell before a run:

- `SB2_DEV_LOCAL_SQL_PASSWORD`
- `SB2_TEST_CLOUD_SQL_PASSWORD`

The text `YOUR_DB_PASSWORD` is a placeholder, not the real password.

This test run refuses SB1, `SQL1002.site4now.net` / `db_abbe78_warehouse`, and the other account databases `db_abe8c0_erp` and `db_abe8c0_luckyone`.

## Dev Local (Dev PC)

| Field | Value |
|-------|-------|
| Data Source | `local\SB2` |
| Initial Catalog | `SB2` |
| User Id | `sa` |
| Password | `YOUR_DB_PASSWORD` in the shell only |
| Extra | `Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;` |

```text
Data Source=local\SB2;Initial Catalog=SB2;User Id=sa;Password=YOUR_DB_PASSWORD;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;
```

Encrypt as: `DBConnection.ini` (next to the agent on the Dev PC, not in git)

## Test Cloud

| Field | Value |
|-------|-------|
| Data Source | `sql8006.site4now.net` |
| Initial Catalog | `db_abe8c0_sb2` |
| User Id | `db_abe8c0_sb2_admin` |
| Password | `YOUR_DB_PASSWORD` in the shell only |
| Extra | `Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;` |

```text
Data Source=sql8006.site4now.net;Initial Catalog=db_abe8c0_sb2;User Id=db_abe8c0_sb2_admin;Password=YOUR_DB_PASSWORD;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;
```

Encrypt as: `CloudConnection.ini` (next to the agent on the Dev PC, not in git)

SSMS smoke on Test Cloud must use database `db_abe8c0_sb2`, not `master`.

## Dev ERP / Agent (Dev PC only)

| Field | Value |
|-------|-------|
| ERP / test folder | `D:\Dev\SB2-Cloud\` |
| SyncAgent exe | `SB.SyncAgent.exe` |
| Tray exe | `SB.SyncStatus.exe` |
| RC4 EncryptKey | `27042005` |
| Windows service name | `SB2.SyncAgent.Dev` |

## Still closed

- `SQL1002.site4now.net` / `db_abbe78_warehouse`
- `db_abe8c0_erp` (`sql8020`) and `db_abe8c0_luckyone` (`sql8010`)
- SB1
- Client PC folder `D:\MinnNandar\Software`
- Production service name `SB.SyncAgent`

## sqlcmd helpers

```bat
REM Dev Local
sqlcmd -S "local\SB2" -d SB2 -U sa -P "YOUR_DB_PASSWORD" -C -I -b -i SCRIPT.sql

REM Test Cloud
sqlcmd -S "sql8006.site4now.net" -d db_abe8c0_sb2 -U db_abe8c0_sb2_admin -P "YOUR_DB_PASSWORD" -C -I -b -i SCRIPT.sql
```

Runners:

- `docs/sql/SB2_Run_LocalBootstrap.ps1` on `local\SB2` / `SB2`
- `docs/sql/SB2_Run_Backup.ps1` on Dev Local
- Restore of the `.bak` onto `db_abe8c0_sb2` is done in the hosting panel. `SB2_Run_TestCloudRestore.ps1` is for a SQL host that allows `RESTORE`; shared hosting already queued that restore.
- `docs/sql/SB2_Run_CloudAfterRestore.ps1` on `sql8006.site4now.net` / `db_abe8c0_sb2`
- `SB.SyncAgent/SB2_Dev_EncryptAndOnce.ps1`
