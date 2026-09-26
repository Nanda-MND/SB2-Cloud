#Requires -Version 5.1
<#
  Dev PC only.
  Build SyncAgent + SyncStatus, encrypt DBConnection.ini and CloudConnection.ini
  for Dev Local + Test Cloud, then run SB.SyncAgent.exe /once.
  Service install is optional and must use SB2.SyncAgent.Dev.

  Refuses SB1, the production cloud host, and client ERP folders.
  Passwords come from -LocalPassword / -CloudPassword or
  SB2_DEV_LOCAL_SQL_PASSWORD / SB2_TEST_CLOUD_SQL_PASSWORD.
  Encrypted ini files are written only under -ErpFolder, never into git.
#>
[CmdletBinding()]
param(
    [string]$ErpFolder = 'D:\Dev\SB2-Cloud-Runtime\',
    [string]$LocalServer = 'localhost',
    [string]$LocalDatabase = 'SB2',
    [string]$LocalUser = 'sa',
    [string]$LocalPassword = $env:SB2_DEV_LOCAL_SQL_PASSWORD,
    [string]$CloudServer = 'sql8006.site4now.net',
    [string]$CloudDatabase = 'db_abe8c0_sb2',
    [string]$CloudUser = 'db_abe8c0_sb2_admin',
    [string]$CloudPassword = $env:SB2_TEST_CLOUD_SQL_PASSWORD,
    [string]$ServiceName = 'SB2.SyncAgent.Dev',
    [switch]$InstallService,
    [switch]$SkipBuild,
    [switch]$SkipOnce
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$common = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\sql\SB2_Run_Common.ps1'
if (-not (Test-Path -LiteralPath $common)) {
    throw "Missing shared guards: $common"
}
. $common

if ($ServiceName -ne $script:Sb2DevServiceName) {
    throw "Service install must use $($script:Sb2DevServiceName). Refusing '$ServiceName'."
}

Assert-Sb2DevErpFolder -ErpFolder $ErpFolder
Assert-Sb2DevTestTarget -Server $LocalServer -Database $LocalDatabase -User $LocalUser -Role Local
Assert-Sb2DevTestTarget -Server $CloudServer -Database $CloudDatabase -User $CloudUser -Role TestCloud
Assert-Sb2ResolvedEndpoint -Server $LocalServer -Database $LocalDatabase -User $LocalUser
Assert-Sb2ResolvedEndpoint -Server $CloudServer -Database $CloudDatabase -User $CloudUser
Assert-Sb2NotDevLocalServer -Server $CloudServer -Database $CloudDatabase -DevLocalServer $LocalServer -DevLocalDatabase $LocalDatabase

Assert-Sb2RealPassword -Password $LocalPassword
Assert-Sb2RealPassword -Password $CloudPassword

$localConn = New-Sb2SqlConnectionString -Server $LocalServer -Database $LocalDatabase -User $LocalUser -Password $LocalPassword
$cloudConn = New-Sb2SqlConnectionString -Server $CloudServer -Database $CloudDatabase -User $CloudUser -Password $CloudPassword
Assert-Sb2ConnectionText -ConnectionText $localConn
Assert-Sb2ConnectionText -ConnectionText $cloudConn

$repo = Get-Sb2RepoRoot -StartPath $PSScriptRoot
$agentProj = Join-Path $repo 'SB.SyncAgent\SB.SyncAgent.csproj'
$statusProj = Join-Path $repo 'SB.SyncStatus\SB.SyncStatus.csproj'

function Get-Sb2MsBuild {
    $list = @(
        "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "$env:ProgramFiles\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "$env:ProgramFiles\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
    )
    foreach ($path in $list) {
        if ($path -and (Test-Path -LiteralPath $path)) { return $path }
    }
    throw 'MSBuild not found. Install Visual Studio Build Tools on the Dev PC.'
}

if (-not $SkipBuild) {
    $msbuild = Get-Sb2MsBuild
    Write-Host 'Building SyncAgent and SyncStatus (Release)'
    & $msbuild $agentProj /p:Configuration=Release /p:Platform=AnyCPU /t:Rebuild /v:minimal
    if ($LASTEXITCODE -ne 0) { throw 'SyncAgent build failed.' }
    & $msbuild $statusProj /p:Configuration=Release /p:Platform=AnyCPU /t:Rebuild /v:minimal
    if ($LASTEXITCODE -ne 0) { throw 'SyncStatus build failed.' }
}

if (-not (Test-Path -LiteralPath $ErpFolder)) {
    New-Item -ItemType Directory -Path $ErpFolder | Out-Null
}

$agentExe = Join-Path $repo 'SB.SyncAgent\bin\Release\SB.SyncAgent.exe'
$statusExe = Join-Path $repo 'SB.SyncStatus\bin\Release\SB.SyncStatus.exe'
if (-not (Test-Path -LiteralPath $agentExe)) { throw "Missing $agentExe" }
if (-not (Test-Path -LiteralPath $statusExe)) { throw "Missing $statusExe" }

Copy-Item -LiteralPath $agentExe -Destination (Join-Path $ErpFolder 'SB.SyncAgent.exe') -Force
Copy-Item -LiteralPath $statusExe -Destination (Join-Path $ErpFolder 'SB.SyncStatus.exe') -Force
foreach ($config in @(
    (Join-Path $repo 'SB.SyncAgent\bin\Release\SB.SyncAgent.exe.config'),
    (Join-Path $repo 'SB.SyncStatus\bin\Release\SB.SyncStatus.exe.config')
)) {
    if (Test-Path -LiteralPath $config) {
        Copy-Item -LiteralPath $config -Destination (Join-Path $ErpFolder (Split-Path -Leaf $config)) -Force
    }
}

$deployedAgent = Join-Path $ErpFolder 'SB.SyncAgent.exe'
Write-Host "Encrypting Dev Local and Test Cloud connection files in $ErpFolder"
& $deployedAgent /encrypt 'DBConnection.ini' $localConn
if ($LASTEXITCODE -ne 0) { throw 'Failed to encrypt DBConnection.ini' }
& $deployedAgent /encrypt 'CloudConnection.ini' $cloudConn
if ($LASTEXITCODE -ne 0) { throw 'Failed to encrypt CloudConnection.ini' }

if (-not $SkipOnce) {
    Write-Host 'Running SB.SyncAgent.exe /once'
    Push-Location $ErpFolder
    try {
        & $deployedAgent /once
        if ($LASTEXITCODE -ne 0) { throw 'SB.SyncAgent.exe /once failed. See SyncAgent.log.' }
    }
    finally {
        Pop-Location
    }
}

if ($InstallService) {
    $installUtil = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe'
    if (-not (Test-Path -LiteralPath $installUtil)) {
        throw 'InstallUtil.exe not found.'
    }
    Write-Host "Installing optional Dev service $ServiceName"
    & $installUtil /i $deployedAgent
    if ($LASTEXITCODE -ne 0) { throw 'InstallUtil failed.' }
    & net start $ServiceName
    if ($LASTEXITCODE -ne 0) { throw "Could not start $ServiceName" }
}

Write-Host 'Dev PC agent step finished. Start SB.SyncStatus.exe from the Dev ERP folder when you want the tray.'
