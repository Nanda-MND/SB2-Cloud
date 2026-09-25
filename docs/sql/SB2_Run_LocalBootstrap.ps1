#Requires -Version 5.1
<#
  Dev Local bootstrap for SB2-Cloud.
  Refuses SB1 and the production cloud host.
  UserRights stays L2C-only. Detail Op=D stays a hard delete.

  Password: -Password or env SB2_DEV_LOCAL_SQL_PASSWORD. Never written to disk.

  Example (Dev PC):
    powershell -File docs\sql\SB2_Run_LocalBootstrap.ps1 `
      -Server 'YOUR_DEV_PC\INSTANCE' -Database SB2 -User sa
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [string]$Database = 'SB2',
    [string]$User = 'sa',
    [string]$Password = $env:SB2_DEV_LOCAL_SQL_PASSWORD
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SB2_Run_Common.ps1')

Assert-Sb2DevTestTarget -Server $Server -Database $Database -User $User -Role Local
Assert-Sb2ResolvedEndpoint -Server $Server -Database $Database -User $User
if ([string]::IsNullOrWhiteSpace($Password)) {
    throw 'Dev Local password is required via -Password or SB2_DEV_LOCAL_SQL_PASSWORD. Do not commit it.'
}

$required = @(
    'SB2_Assert_NotSB1OrProd.sql',
    'DataSync_01_Schema.sql',
    'DataSync_04_SoftDelete_Migration.sql',
    'DataSync_10_SyncApply_Generic.sql',
    'DataSync_03_ApplyInbound.sql',
    'DataSync_11_AllTables_Install.sql',
    'DataSync_11_RunLocal.sql',
    'DataSync_14_MasterPriority.sql',
    'DataSync_15_ERPTransactionTables.sql',
    'Deploy_TxnDetail_HardDeleteSync_LOCAL.sql',
    'Deploy_EditDeleteSync_LOCAL.sql',
    'Update_AllowDelete_AdminUsers_MenuID2.sql',
    'DataSync_UserRights_L2C_Only_Local.sql',
    'Fix_Duplicate_UserRights_BothSides.sql',
    'Sales_Listview_NarrowCarDiscount.sql',
    'SB2_Assert_DetailHardDelete.sql'
)

$generic = Join-Path $PSScriptRoot 'DataSync_10_SyncApply_Generic.sql'
$genericText = Get-Content -LiteralPath $generic -Raw
if ($genericText -notmatch 'hardDeleteDetail') {
    throw 'DataSync_10_SyncApply_Generic.sql is missing hardDeleteDetail. Detail Op=D would not hard-delete.'
}
if ($genericText -notmatch 'preserve-soft-delete-flags') {
    throw 'DataSync_10_SyncApply_Generic.sql is missing preserve-soft-delete-flags. Head Op=D must stay a soft delete.'
}

foreach ($name in $required) {
    $path = Join-Path $PSScriptRoot $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required script: $name"
    }
}

# Cloud-only scripts must never run from this runner.
$forbiddenHere = @('DataSync_28_EnableC2L_Capture.sql', 'DataSync_11_RunCloud.sql', 'Deploy_TxnDetail_HardDeleteSync_CLOUD.sql', 'Deploy_EditDeleteSync_CLOUD.sql')
foreach ($name in $forbiddenHere) {
    if ($required -contains $name) {
        throw "Local bootstrap must not run $name."
    }
}

Write-Host "Dev Local bootstrap on $Server / $Database"
Write-Host 'UserRights L2C-only. Detail Op=D = hard delete.'

Invoke-Sb2SqlFiles -Server $Server -Database $Database -User $User -Password $Password -SqlDir $PSScriptRoot -Files $required
Invoke-Sb2SqlFile -Server $Server -Database $Database -User $User -Password $Password `
    -File (Join-Path $PSScriptRoot 'SB2_Assert_UserRights_L2C.sql') `
    -Variables @{ Role = 'Local' }

Write-Host 'Dev Local bootstrap finished.'
