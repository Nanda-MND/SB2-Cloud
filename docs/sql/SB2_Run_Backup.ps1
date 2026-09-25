#Requires -Version 5.1
<#
  Full COPY_ONLY backup of Dev Local after bootstrap.
  Refuses SB1 and the production cloud host.
  Password: -Password or env SB2_DEV_LOCAL_SQL_PASSWORD. Never written to disk.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [string]$Database = 'SB2',
    [string]$User = 'sa',
    [string]$Password = $env:SB2_DEV_LOCAL_SQL_PASSWORD,
    [Parameter(Mandatory = $true)][string]$BackupPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SB2_Run_Common.ps1')

Assert-Sb2DevTestTarget -Server $Server -Database $Database -User $User -Role Local
Assert-Sb2ResolvedEndpoint -Server $Server -Database $Database -User $User
if ([string]::IsNullOrWhiteSpace($Password)) {
    throw 'Dev Local password is required via -Password or SB2_DEV_LOCAL_SQL_PASSWORD. Do not commit it.'
}
if ($BackupPath -match '(?i)site4now|abbe78|\\SB1\\') {
    throw 'Refusing a backup path that looks like SB1 or production cloud storage.'
}

Add-Type -AssemblyName System.Data
$cs = New-Sb2SqlConnectionString -Server $Server -Database $Database -User $User -Password $Password
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $cs
$builder.InitialCatalog = 'master'

$escapedPath = $BackupPath.Replace("'", "''")
$sql = @"
BACKUP DATABASE [$Database] TO DISK = N'$escapedPath' WITH COPY_ONLY, INIT, CHECKSUM, STATS = 5;
"@

Write-Host "Dev Local backup $Server / $Database"
$conn = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
try {
    $conn.Open()
    $probe = $conn.CreateCommand()
    $probe.CommandText = "SELECT CONVERT(nvarchar(256), @@SERVERNAME) AS Srv, DB_ID(N'$Database') AS Id;"
    $probe.CommandTimeout = 30
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $probe
    $probeTable = New-Object System.Data.DataTable
    [void]$adapter.Fill($probeTable)
    $srv = [string]$probeTable.Rows[0]['Srv']
    if ($srv -match '(?i)site4now|SQL1002') {
        throw "Refusing production cloud host reported by @@SERVERNAME ($srv)."
    }
    if ($probeTable.Rows[0]['Id'] -is [DBNull]) {
        throw "Database $Database was not found on $Server."
    }

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sql
    $cmd.CommandTimeout = 0
    [void]$cmd.ExecuteNonQuery()
}
finally {
    $conn.Close()
}

Write-Host "Backup written to $BackupPath"
