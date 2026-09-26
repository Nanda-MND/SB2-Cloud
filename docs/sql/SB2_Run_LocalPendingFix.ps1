#Requires -Version 5.1
<#
  Dev Local only (localhost / SB2). Does not reseed identities and does not
  requeue PurchaseHead deletes.

  1) Redeploy SyncApply_Generic so Head Op=D soft-applies (int PK vs sql_variant).
  2) Turn UserStatus and ListviewItem sync off and clear their pending outbox.

  Password: -Password or env SB2_DEV_LOCAL_SQL_PASSWORD. Never written to disk.
#>
[CmdletBinding()]
param(
    [string]$Server = 'localhost',
    [string]$Database = 'SB2',
    [string]$User = 'sa',
    [string]$Password = $env:SB2_DEV_LOCAL_SQL_PASSWORD
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SB2_Run_Common.ps1')

Assert-Sb2DevTestTarget -Server $Server -Database $Database -User $User -Role Local
Assert-Sb2ResolvedEndpoint -Server $Server -Database $Database -User $User
Assert-Sb2RealPassword -Password $Password

$files = @(
    'DataSync_10_SyncApply_Generic.sql',
    'SB2_Disable_UserStatus_And_Listview_Sync.sql'
)

foreach ($name in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $name))) {
        throw "Missing required script: $name"
    }
}

$generic = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'DataSync_10_SyncApply_Generic.sql') -Raw
if ($generic -notmatch 'hardDeleteDetail') {
    throw 'DataSync_10_SyncApply_Generic.sql is missing hardDeleteDetail.'
}
if ($generic -notmatch 'preserve-soft-delete-flags') {
    throw 'DataSync_10_SyncApply_Generic.sql is missing preserve-soft-delete-flags.'
}

Write-Host "Dev Local pending fix on $Server / $Database"
Write-Host 'UserStatus and ListviewItem sync off. Head Op=D stays a soft delete. No identity reseed.'

Invoke-Sb2SqlFiles -Server $Server -Database $Database -User $User -Password $Password -SqlDir $PSScriptRoot -Files $files

Write-Host 'Dev Local pending fix finished.'
