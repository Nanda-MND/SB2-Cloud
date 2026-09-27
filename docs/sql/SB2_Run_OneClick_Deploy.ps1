#Requires -Version 5.1
<#
  SB2 one-click for the verified pair only.

  Local localhost / SB2  ->  COPY_ONLY backup  ->  restore onto
  Cloud tcp:sql8006.site4now.net,1433 / db_abe8c0_sb2  ->  cloud SQL pack.

  Refuses SQL1002, db_abbe78_warehouse, db_abe8c0_erp, db_abe8c0_luckyone, SB1,
  and the Client PC folder D:\MinnNandar\Software.
  Does not install Windows service SB.SyncAgent. Does not rebuild SB.exe.

  Phase Local — fix Local (PendingFix), then backup. Restore the .bak in the
                hosting panel. Shared hosting does not accept RESTORE from here.
  Phase Cloud — run the cloud SQL pack (SB2_CloudAfterRestore_Ordered.sql).
  Phase All   — Local + backup. Runs restore and cloud SQL only with -RestoreOnCloud.

  Passwords stay in SB2_DEV_LOCAL_SQL_PASSWORD and SB2_TEST_CLOUD_SQL_PASSWORD.
  They are never written to disk.

  Example:
    powershell -File docs\sql\SB2_Run_OneClick_Deploy.ps1 -Phase Local -BackupPath D:\Dev\SB2-Cloud-Runtime\SB2_copyonly.bak
    powershell -File docs\sql\SB2_Run_OneClick_Deploy.ps1 -Phase Cloud
#>
[CmdletBinding()]
param(
    [ValidateSet('Local', 'Cloud', 'All')]
    [string]$Phase = 'Local',
    [string]$BackupPath = '',
    [switch]$IncludeBootstrap,
    [switch]$RestoreOnCloud,
    [string]$DataFolder = '',
    [string]$LogFolder = '',
    [switch]$AllowReplace,
    [switch]$EnableTxnC2L
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SB2_Run_Common.ps1')

if ($BackupPath -match '(?i)MinnNandar|site4now|abbe78|\\SB1\\') {
    throw 'Refusing a backup path under the Client PC folder, SB1, or production cloud storage.'
}

function Get-Sb2CloudPackNames {
    $ordered = Join-Path $PSScriptRoot 'SB2_CloudAfterRestore_Ordered.sql'
    if (-not (Test-Path -LiteralPath $ordered)) {
        throw "Missing cloud SQL pack: $ordered"
    }
    $names = New-Object System.Collections.Generic.List[string]
    foreach ($line in Get-Content -LiteralPath $ordered) {
        if ($line -match '^:r \.\\(.+\.sql)\s*$') {
            $names.Add($Matches[1])
        }
    }
    if ($names.Count -lt 1) {
        throw 'SB2_CloudAfterRestore_Ordered.sql has no :r includes.'
    }
    return $names
}

function Show-Sb2CloudPack {
    Write-Host 'Cloud SQL after restore (do not run these on Local):'
    $i = 1
    foreach ($name in (Get-Sb2CloudPackNames)) {
        Write-Host ("  {0,2}. {1}" -f $i, $name)
        $i++
    }
    Write-Host 'Pack file: docs\sql\SB2_CloudAfterRestore_Ordered.sql'
    Write-Host 'Runner:    docs\sql\SB2_Run_CloudAfterRestore.ps1  (no -EnableTxnC2L unless you pass it)'
}

if ($RestoreOnCloud -and $Phase -ne 'All') {
    throw '-RestoreOnCloud is only valid with -Phase All. Phase Cloud runs SQL on a database that is already restored.'
}
if ($IncludeBootstrap -and $Phase -eq 'Cloud') {
    throw '-IncludeBootstrap applies to Phase Local or All only.'
}

if ($Phase -eq 'Local' -or $Phase -eq 'All') {
    if ([string]::IsNullOrWhiteSpace($BackupPath)) {
        throw 'Phase Local/All needs -BackupPath on the Dev PC. Example: D:\Dev\SB2-Cloud-Runtime\SB2_copyonly.bak'
    }
    if ($IncludeBootstrap) {
        Write-Host 'One-click: Local bootstrap, then PendingFix.'
        & (Join-Path $PSScriptRoot 'SB2_Run_LocalBootstrap.ps1')
    }
    Write-Host 'One-click: LocalPendingFix (L2C triggers, identity below 1999999999, UserStatus off).'
    & (Join-Path $PSScriptRoot 'SB2_Run_LocalPendingFix.ps1')
    Write-Host 'One-click: COPY_ONLY backup. Cloud reseed has not run yet; the .bak still has Local identity values.'
    & (Join-Path $PSScriptRoot 'SB2_Run_Backup.ps1') -BackupPath $BackupPath
}

if ($RestoreOnCloud) {
    if ([string]::IsNullOrWhiteSpace($DataFolder) -or [string]::IsNullOrWhiteSpace($LogFolder)) {
        throw '-RestoreOnCloud needs -DataFolder and -LogFolder on the Cloud SQL host. Shared hosting: restore in the panel instead, then -Phase Cloud.'
    }
    Write-Host 'One-click: RESTORE onto Test Cloud sql8006 / db_abe8c0_sb2.'
    $restoreArgs = @{
        BackupPath = $BackupPath
        DataFolder = $DataFolder
        LogFolder  = $LogFolder
    }
    if ($AllowReplace) { $restoreArgs['AllowReplace'] = $true }
    & (Join-Path $PSScriptRoot 'SB2_Run_TestCloudRestore.ps1') @restoreArgs
}

if ($Phase -eq 'Cloud' -or ($Phase -eq 'All' -and $RestoreOnCloud)) {
    Write-Host 'One-click: cloud SQL pack. This reseeds Cloud identities to >= 2000000000.'
    Show-Sb2CloudPack
    $cloud = Join-Path $PSScriptRoot 'SB2_Run_CloudAfterRestore.ps1'
    if ($EnableTxnC2L) {
        Write-Host 'Extra Sale/Purchase/Transfer C2L packs are on. The ordered .sql file does not include those three files.'
        & $cloud -EnableTxnC2L
    }
    else {
        & $cloud
    }
    Write-Host 'One-click cloud SQL finished. Next on the Dev PC only: SB.SyncAgent\SB2_Dev_EncryptAndOnce.ps1'
    Write-Host 'Do not install service SB.SyncAgent. Do not copy into D:\MinnNandar\Software.'
    return
}

if ($Phase -eq 'Local' -or $Phase -eq 'All') {
    Write-Host "Backup is at $BackupPath"
    Write-Host 'Next: restore that .bak as db_abe8c0_sb2 in the hosting panel (shared hosting blocks RESTORE from here).'
    Write-Host 'Then: powershell -File docs\sql\SB2_Run_OneClick_Deploy.ps1 -Phase Cloud'
    Show-Sb2CloudPack
}
