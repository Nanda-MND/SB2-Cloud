#Requires -Version 5.1
<#
  Test Cloud scripts after the Dev Local backup has been restored.
  Does not run Local capture (DataSync_11_RunLocal.sql).
  UserRights stays L2C-only (CaptureCloud=0). Detail Op=D stays a hard delete.
  Refuses SB1 and the production cloud host.

  Password: -Password or env SB2_TEST_CLOUD_SQL_PASSWORD. Never written to disk.
  -EnableTxnC2L adds Sale/Purchase/Transfer C2L packs, then re-asserts UserRights L2C-only.
#>
[CmdletBinding()]
param(
    [string]$Server = 'sql8006.site4now.net',
    [string]$Database = 'db_abe8c0_sb2',
    [string]$User = 'db_abe8c0_sb2_admin',
    [string]$Password = $env:SB2_TEST_CLOUD_SQL_PASSWORD,
    [string]$DevLocalServer = 'local\SB2',
    [string]$DevLocalDatabase = 'SB2',
    [switch]$EnableTxnC2L
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SB2_Run_Common.ps1')

Assert-Sb2DevTestTarget -Server $Server -Database $Database -User $User -Role TestCloud
Assert-Sb2ResolvedEndpoint -Server $Server -Database $Database -User $User
Assert-Sb2NotDevLocalServer -Server $Server -Database $Database -DevLocalServer $DevLocalServer -DevLocalDatabase $DevLocalDatabase
Assert-Sb2RealPassword -Password $Password

$scripts = @(
    'SB2_Assert_NotSB1OrProd.sql',
    'DataSync_10_SyncApply_Generic.sql',
    'DataSync_28_EnableC2L_Capture.sql',
    'Deploy_TxnDetail_HardDeleteSync_CLOUD.sql',
    'Deploy_EditDeleteSync_CLOUD.sql',
    'DataSync_UserRights_L2C_Only.sql'
)

if ($EnableTxnC2L) {
    $scripts += @(
        'DataSync_32_EnableC2L_Sale.sql',
        'DataSync_35_EnableC2L_Transfer.sql',
        'DataSync_36_EnableC2L_Purchase.sql',
        'DataSync_UserRights_L2C_Only.sql'
    )
}

$scripts += @(
    'Sales_Listview_NarrowCarDiscount.sql',
    'SB2_Assert_DetailHardDelete.sql'
)

$banned = @('DataSync_11_RunLocal.sql', 'Deploy_TxnDetail_HardDeleteSync_LOCAL.sql', 'Deploy_EditDeleteSync_LOCAL.sql', 'DataSync_UserRights_L2C_Only_Local.sql')
foreach ($name in $banned) {
    if ($scripts -contains $name) {
        throw "Test Cloud runner must not execute $name."
    }
}

foreach ($name in $scripts) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $name))) {
        throw "Missing required script: $name"
    }
}

Write-Host "Test Cloud after-restore on $Server / $Database"
Write-Host 'UserRights L2C-only. Detail Op=D = hard delete. Local capture is not installed here.'
Write-Host 'UserRights assert uses sqlcmd -v Role=TestCloud.'

Invoke-Sb2SqlFiles -Server $Server -Database $Database -User $User -Password $Password -SqlDir $PSScriptRoot -Files $scripts
Invoke-Sb2SqlFile -Server $Server -Database $Database -User $User -Password $Password `
    -File (Join-Path $PSScriptRoot 'SB2_Assert_UserRights_L2C.sql') `
    -Variables @{ Role = 'TestCloud' }

Write-Host 'Test Cloud after-restore finished.'
