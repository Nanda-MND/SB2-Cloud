#Requires -Version 5.1
<#
  Restore a Dev Local .bak onto Test Cloud only.
  Refuses SB1 and the production cloud host.
  Does not re-run Local capture install.
  -DataFolder and -LogFolder are paths on the Test Cloud SQL host, not the Dev PC.

  Password: -Password or env SB2_TEST_CLOUD_SQL_PASSWORD. Never written to disk.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [Parameter(Mandatory = $true)][string]$Database,
    [Parameter(Mandatory = $true)][string]$User,
    [string]$Password = $env:SB2_TEST_CLOUD_SQL_PASSWORD,
    [Parameter(Mandatory = $true)][string]$BackupPath,
    [Parameter(Mandatory = $true)][string]$DataFolder,
    [Parameter(Mandatory = $true)][string]$LogFolder,
    [string]$DevLocalServer = '',
    [string]$DevLocalDatabase = 'SB2',
    [switch]$AllowReplace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SB2_Run_Common.ps1')

Assert-Sb2DevTestTarget -Server $Server -Database $Database -User $User -Role TestCloud
Assert-Sb2ResolvedEndpoint -Server $Server -Database $Database -User $User
Assert-Sb2NotDevLocalServer -Server $Server -Database $Database -DevLocalServer $DevLocalServer -DevLocalDatabase $DevLocalDatabase
if ([string]::IsNullOrWhiteSpace($Password)) {
    throw 'Test Cloud password is required via -Password or SB2_TEST_CLOUD_SQL_PASSWORD. Do not commit it.'
}
if (-not (Test-Path -LiteralPath $BackupPath)) {
    throw "Backup file not found: $BackupPath"
}
if ($BackupPath -match '(?i)site4now|abbe78') {
    throw 'Refusing a backup path that looks like production cloud storage.'
}

Add-Type -AssemblyName System.Data
$cs = New-Sb2SqlConnectionString -Server $Server -Database 'master' -User $User -Password $Password
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $cs
$builder.InitialCatalog = 'master'

function Invoke-Sb2NonQuery {
    param($Connection, [string]$Sql, [int]$Timeout = 0)
    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = $Timeout
    return $cmd.ExecuteNonQuery()
}

function Invoke-Sb2Table {
    param($Connection, [string]$Sql)
    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = 0
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
    $table = New-Object System.Data.DataTable
    [void]$adapter.Fill($table)
    return $table
}

$escapedBak = $BackupPath.Replace("'", "''")
Write-Host "Test Cloud restore onto $Server / $Database"

$conn = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
try {
    $conn.Open()
    $srv = [string](Invoke-Sb2Table -Connection $conn -Sql 'SELECT CONVERT(nvarchar(256), @@SERVERNAME) AS Srv;').Rows[0]['Srv']
    if ($srv -match '(?i)site4now|SQL1002') {
        throw "Refusing production cloud host reported by @@SERVERNAME ($srv)."
    }

    $exists = Invoke-Sb2Table -Connection $conn -Sql ("SELECT DB_ID(N'" + $Database.Replace("'", "''") + "') AS Id;")
    $dbId = $exists.Rows[0]['Id']
    if ($dbId -isnot [DBNull] -and $null -ne $dbId -and -not $AllowReplace) {
        throw "Database $Database already exists on the Test Cloud host. Re-run with -AllowReplace to replace it."
    }

    $files = Invoke-Sb2Table -Connection $conn -Sql ("RESTORE FILELISTONLY FROM DISK = N'" + $escapedBak + "';")
    if ($files.Rows.Count -eq 0) {
        throw 'RESTORE FILELISTONLY returned no files.'
    }

    if (-not (Test-Path -LiteralPath $DataFolder)) {
        New-Item -ItemType Directory -Path $DataFolder | Out-Null
    }
    if (-not (Test-Path -LiteralPath $LogFolder)) {
        New-Item -ItemType Directory -Path $LogFolder | Out-Null
    }

    $moves = New-Object System.Collections.Generic.List[string]
    $dataIndex = 0
    $logIndex = 0
    foreach ($row in $files.Rows) {
        $logical = [string]$row['LogicalName']
        $type = ([string]$row['Type']).Trim()
        $logicalSql = $logical.Replace("'", "''")
        if ($type -eq 'L') {
            $suffix = ''
            if ($logIndex -gt 0) { $suffix = '_' + $logIndex }
            $target = Join-Path $LogFolder ($Database + $suffix + '_log.ldf')
            $logIndex++
        }
        else {
            $suffix = ''
            if ($dataIndex -gt 0) { $suffix = '_' + $dataIndex }
            $target = Join-Path $DataFolder ($Database + $suffix + '.mdf')
            $dataIndex++
        }
        $targetSql = $target.Replace("'", "''")
        $moves.Add("MOVE N'$logicalSql' TO N'$targetSql'")
    }

    $replace = ''
    if ($AllowReplace) { $replace = 'REPLACE, ' }
    $restore = "RESTORE DATABASE [$Database] FROM DISK = N'$escapedBak' WITH " + ($moves -join ', ') + ", $replace RECOVERY, STATS = 5;"
    [void](Invoke-Sb2NonQuery -Connection $conn -Sql $restore)

    $conn.ChangeDatabase($Database)
    $smoke = Invoke-Sb2Table -Connection $conn -Sql @"
SELECT DB_NAME() AS DbName,
       CONVERT(nvarchar(256), @@SERVERNAME) AS Srv,
       OBJECT_ID(N'dbo.SyncConfig', N'U') AS SyncConfigId;
"@
    $restoredDb = [string]$smoke.Rows[0]['DbName']
    $restoredSrv = [string]$smoke.Rows[0]['Srv']
    if ($restoredDb -match '^(?i)SB1$' -or $restoredSrv -match '(?i)site4now|SQL1002') {
        throw 'Restore landed on SB1 or the production cloud host.'
    }
    if ($smoke.Rows[0]['SyncConfigId'] -is [DBNull]) {
        throw 'Smoke failed: dbo.SyncConfig is missing after restore.'
    }
    Write-Host "Restored DB=$restoredDb Server=$restoredSrv"
}
finally {
    $conn.Close()
}

Write-Host 'Test Cloud restore smoke completed. Next: SB2_Run_CloudAfterRestore.ps1'
