# SB2-Cloud connections — DEV / TEST only

Environment flag: `DEV_TEST`

Passwords are not stored in this file and must not be committed.  
Keep them in a password manager and pass them to the runners at execution time  
(`SB2_DEV_LOCAL_SQL_PASSWORD`, `SB2_TEST_CLOUD_SQL_PASSWORD`).

This phase refuses SB1 and the production cloud host `SQL1002.site4now.net` / `db_abbe78_warehouse`.

## Dev Local (Dev PC)

| Field | Value |
|-------|-------|
| Data Source | `YOUR_DEV_PC\INSTANCE` |
| Initial Catalog | `SB2` |
| User Id | `sa` |
| Password | *(password manager only — never commit)* |
| Extra | `Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;` |

```text
Data Source=YOUR_DEV_PC\INSTANCE;Initial Catalog=SB2;User Id=sa;Password=***;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;
```

Encrypt as: `DBConnection.ini` (next to the agent on the Dev PC, not in git)

## Test Cloud (not production)

| Field | Value |
|-------|-------|
| Data Source | `YOUR_TEST_CLOUD_HOST` |
| Initial Catalog | `YOUR_TEST_CLOUD_DB` |
| User Id | `YOUR_TEST_CLOUD_USER` |
| Password | *(password manager only — never commit)* |
| Extra | `Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;` |

```text
Data Source=YOUR_TEST_CLOUD_HOST;Initial Catalog=YOUR_TEST_CLOUD_DB;User Id=YOUR_TEST_CLOUD_USER;Password=***;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;
```

Encrypt as: `CloudConnection.ini` (next to the agent on the Dev PC, not in git)

## Dev ERP / Agent (Dev PC only)

| Field | Value |
|-------|-------|
| ERP / test folder | `D:\Dev\SB2-Cloud\` |
| SyncAgent exe | `SB.SyncAgent.exe` |
| Tray exe | `SB.SyncStatus.exe` |
| RC4 EncryptKey | `27042005` |
| Windows service name | `SB2.SyncAgent.Dev` |

## Forbidden in this file until a separate Live/Client cutover is approved

- Live Local server / live cloud catalog (`SQL1002.site4now.net`, `db_abbe78_warehouse`)
- SB1 (`SB1` database or `Server\SB1`)
- Client PC `ErpInstallPath` (including `D:\MinnNandar\Software`)
- Production SyncAgent service name on customer machines (`SB.SyncAgent`)

## sqlcmd helpers (Dev / Test)

```bat
REM Dev Local — password from the password manager, never from git
sqlcmd -S "YOUR_DEV_PC\INSTANCE" -d SB2 -U sa -P "***" -C -I -b -i SCRIPT.sql

REM Test Cloud
sqlcmd -S "YOUR_TEST_CLOUD_HOST" -d YOUR_TEST_CLOUD_DB -U YOUR_TEST_CLOUD_USER -P "***" -C -I -b -i SCRIPT.sql
```

Runners (they refuse SB1 and the production cloud host):

- `docs/sql/SB2_Run_LocalBootstrap.ps1`
- `docs/sql/SB2_Run_Backup.ps1`
- `docs/sql/SB2_Run_TestCloudRestore.ps1`
- `docs/sql/SB2_Run_CloudAfterRestore.ps1`
- `SB.SyncAgent/SB2_Dev_EncryptAndOnce.ps1`
