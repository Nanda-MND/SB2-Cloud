# SB2-Cloud connections — DEV / TEST only

Copy to `SB2_CONNECTIONS.md` inside the **SB2-Cloud** repo.  
Fill **Dev PC + Test Cloud** values only. Do **not** put Live/Client endpoints here during the first phase.

Environment flag: `DEV_TEST`

## Dev Local (Dev PC)

| Field | Value |
|-------|-------|
| Data Source | `YOUR_DEV_PC\INSTANCE` |
| Initial Catalog | `SB2` (or your Dev DB name) |
| User Id | `sa` |
| Password | *(password manager only — never commit)* |
| Extra | `Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;` |

```text
Data Source=YOUR_DEV_PC\INSTANCE;Initial Catalog=SB2;User Id=sa;Password=***;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;
```

Encrypt as: `DBConnection.ini`

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

Encrypt as: `CloudConnection.ini`

## Dev ERP / Agent (Dev PC only)

| Field | Value |
|-------|-------|
| ERP / runtime folder | `D:\Dev\SB2-Cloud-Runtime\` (no `.git`; not the repo checkout, not a Client PC path) |
| SyncAgent exe | `SB.SyncAgent.exe` |
| Tray exe | `SB.SyncStatus.exe` |
| RC4 EncryptKey | confirm vs WinForms (`27042005` in SB) |
| Windows service name | `SB2.SyncAgent.Dev` (avoid colliding with live) |

## Forbidden in this file until cutover

- Live Local server / live cloud catalog  
- Client PC `ErpInstallPath`  
- Production SyncAgent service name on customer machines  

## sqlcmd helpers (Dev / Test)

```bat
REM Dev Local
sqlcmd -S "YOUR_DEV_PC\INSTANCE" -d SB2 -U sa -P "***" -C -I -b -i SCRIPT.sql

REM Test Cloud
sqlcmd -S "YOUR_TEST_CLOUD_HOST" -d YOUR_TEST_CLOUD_DB -U YOUR_TEST_CLOUD_USER -P "***" -C -I -b -i SCRIPT.sql
```
