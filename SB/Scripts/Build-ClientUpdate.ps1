<#
.SYNOPSIS
  Build separate SB2 Database and Application one-click update packages.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File D:\Project\SB2\SB\Scripts\Build-ClientUpdate.ps1
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $ProjectRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
}
$ver = Get-Date -Format 'yyyyMMdd'
$outRoot = Join-Path $ProjectRoot 'ClientUpdate'
$dbTpl = Join-Path $outRoot '_templates\DB'
$appTpl = Join-Path $outRoot '_templates\App'
$dbPkg = Join-Path $outRoot "SB2_DB_Update_$ver"
$appPkg = Join-Path $outRoot "SB2_App_Update_$ver"
$bin = Join-Path $ProjectRoot 'SB\bin\Debug'
$scripts = Join-Path $ProjectRoot 'SB\Scripts'

if (-not (Test-Path (Join-Path $bin 'SB.exe'))) {
    throw "SB.exe not found at $bin - build the SB project first."
}
foreach ($p in @($dbTpl, $appTpl)) {
    if (-not (Test-Path $p)) { throw "Template missing: $p" }
}

function New-CleanDir([string]$Path) {
    if (Test-Path $Path) { Remove-Item $Path -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

Write-Host "Building DB package : $dbPkg"
New-CleanDir $dbPkg
Copy-Item "$dbTpl\*" $dbPkg -Recurse -Force
New-Item -ItemType Directory -Force -Path "$dbPkg\Scripts" | Out-Null
Copy-Item "$scripts\ClientDeploy_OneClick.sql"      "$dbPkg\Scripts\01_Core_OneClick.sql" -Force
Copy-Item "$scripts\ClientDeploy_ReturnReceive.sql" "$dbPkg\Scripts\02_ReturnReceive.sql" -Force
Copy-Item "$scripts\Fix_MenuSub_ReturnReceive.sql"  "$dbPkg\Scripts\02b_Fix_MenuSub_Menus.sql" -Force
Copy-Item "$scripts\Fix_MenuSub_Report1150.sql"     "$dbPkg\Scripts\02c_Fix_MenuSub_Reports1150.sql" -Force
Copy-Item "$scripts\Disable_GoodsReceiveManu_Menu35.sql" "$dbPkg\Scripts\02d_Disable_GoodsReceiveManu.sql" -Force
Copy-Item "$scripts\BalanceSheet.sql"               "$dbPkg\Scripts\03_BalanceSheet.sql" -Force

Write-Host "Building App package: $appPkg"
New-CleanDir $appPkg
Copy-Item "$appTpl\*" $appPkg -Recurse -Force
New-Item -ItemType Directory -Force -Path "$appPkg\App","$appPkg\Reports" | Out-Null
Copy-Item "$bin\SB.exe" "$appPkg\App\" -Force
Copy-Item "$bin\SB.exe.config" "$appPkg\App\" -Force -ErrorAction SilentlyContinue
Copy-Item "$bin\SB.pdb" "$appPkg\App\" -Force -ErrorAction SilentlyContinue
Copy-Item "$bin\ObjectListView.dll" "$appPkg\App\" -Force -ErrorAction SilentlyContinue

$reports = @(
    'BankStatement.rpt','PNL.rpt','PurchaseReturnByInvoice.rpt','ReturnStockByInvoice.rpt',
    'PurchaseByItemSummary.rpt','SaleByItemDetail.rpt','BalanceByReturnStock.rpt',
    'AccountOpening.rpt','GL_Detail.rpt','TrialBalance.rpt','Journal.rpt',
    'GeneralLedgerDetail.rpt','GeneralLedgerSummary.rpt','BankClosing.rpt','PurchaseNSales.rpt'
)
$rsrc = Join-Path $bin 'Reports'
$missing = @()
foreach ($r in $reports) {
    $p = Join-Path $rsrc $r
    if (Test-Path $p) { Copy-Item $p "$appPkg\Reports\" -Force }
    else { $missing += $r }
}
if ($missing.Count -gt 0) {
    Write-Warning ("Missing reports (skipped): " + ($missing -join ', '))
}

$dbZip = Join-Path $outRoot "SB2_DB_Update_$ver.zip"
$appZip = Join-Path $outRoot "SB2_App_Update_$ver.zip"
foreach ($z in @($dbZip, $appZip)) { if (Test-Path $z) { Remove-Item $z -Force } }
Compress-Archive -Path $dbPkg -DestinationPath $dbZip -Force
Compress-Archive -Path $appPkg -DestinationPath $appZip -Force

Write-Host ''
Write-Host 'DONE - two separate packages'
Write-Host "  DB  folder: $dbPkg"
Write-Host "  DB  zip   : $dbZip"
Write-Host "  App folder: $appPkg"
Write-Host "  App zip   : $appZip"
Write-Host ''
Write-Host 'Deploy order:'
Write-Host '  1) DB package on SQL Server  -> 00_Update_DB.bat'
Write-Host '  2) App package on each PC   -> 00_Update_App.bat'
