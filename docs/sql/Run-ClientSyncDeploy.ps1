#Requires -Version 3.0
param(
    [string]$LocalServer = "Server\SB1",
    [string]$LocalDatabase = "SB1",
    [string]$LocalUser = "sa",
    [string]$LocalPassword = "",
    [string]$CloudServer = "SQL1002.site4now.net",
    [string]$CloudDatabase = "db_abbe78_warehouse",
    [string]$CloudUser = "db_abbe78_warehouse_admin",
    [string]$CloudPassword = "",
    [string]$ErpPath = "",
    [switch]$SkipCloud,
    [switch]$SkipSql,
    [switch]$SkipBuild,
    [switch]$InstallService,
    [switch]$FullSync,
    [switch]$SeedOutbox
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

$SqlScripts = @(
    "DataSync_01_Schema.sql",
    "DataSync_04_SoftDelete_Migration.sql",
    "DataSync_03_ApplyInbound.sql",
    "DataSync_02_ChangeCapture_Template.sql"
)

$FullSyncLocalScripts = @(
    "DataSync_01_Schema.sql",
    "DataSync_03_ApplyInbound.sql",
    "DataSync_10_SyncApply_Generic.sql",
    "DataSync_05_Sales.sql",
    "DataSync_06_Purchase.sql",
    "DataSync_11_AllTables_Install.sql",
    "DataSync_14_MasterPriority.sql"
)

$FullSyncCloudScripts = @(
    "DataSync_01_Schema.sql",
    "DataSync_03_ApplyInbound.sql",
    "DataSync_10_SyncApply_Generic.sql",
    "DataSync_05_Sales.sql",
    "DataSync_06_Purchase.sql",
    "DataSync_11_AllTables_Install.sql",
    "DataSync_14_MasterPriority.sql"
)

$CloudSqlScripts = @(
    "DataSync_01_Schema.sql",
    "DataSync_04_SoftDelete_Migration.sql",
    "DataSync_03_ApplyInbound.sql"
)

function Get-SqlCmdPath {
    $cmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "sqlcmd not found. Install SQL Server Command Line Utilities."
}

function Get-MsBuildPath {
    $list = @(
        ($env:ProgramFiles + "\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"),
        ($env:ProgramFiles + "\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"),
        ($env:ProgramFiles + "\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"),
        ($env:ProgramFiles + " (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"),
        ($env:windir + "\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe")
    )
    foreach ($p in $list) {
        if (Test-Path $p) { return $p }
    }
    throw "MSBuild not found. Install Visual Studio Build Tools."
}

function Invoke-SqlFile {
    param(
        [string]$Server,
        [string]$Database,
        [string]$User,
        [string]$Password,
        [string]$File,
        [hashtable]$Vars = @{}
    )
    $sqlcmd = Get-SqlCmdPath
    $name = Split-Path $File -Leaf
    Write-Host ("  SQL: " + $name) -ForegroundColor Cyan
    $args = @("-S", $Server, "-d", $Database, "-U", $User, "-P", $Password, "-C", "-I", "-b", "-i", $File)
    foreach ($key in $Vars.Keys) {
        $args += "-v"
        $args += ($key + "=" + $Vars[$key])
    }
    & $sqlcmd @args
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed: " + $File)
    }
}

function Get-ErpFolder {
    param([string]$Hint)
    if ($Hint -and (Test-Path (Join-Path $Hint "SB.exe"))) {
        return (Resolve-Path $Hint).Path
    }
    $searches = @("D:\MinnNandar\Software", "C:\SB", "D:\SB", "C:\Program Files\SB")
    foreach ($s in $searches) {
        if (Test-Path (Join-Path $s "SB.exe")) {
            return (Resolve-Path $s).Path
        }
    }
    return $null
}

function Read-PlainPassword {
    param([string]$Prompt)
    $sec = Read-Host $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

Write-Host ""
Write-Host "=== SB Sync Client Deploy ===" -ForegroundColor Green
Write-Host ("Repo: " + $RepoRoot)
Write-Host ""

if (-not $LocalPassword) {
    $LocalPassword = Read-PlainPassword -Prompt "Enter local SQL password"
}

Write-Host "Step 1: Test Local SQL..." -ForegroundColor Yellow
$sqlcmd = Get-SqlCmdPath
& $sqlcmd -S $LocalServer -d $LocalDatabase -U $LocalUser -P $LocalPassword -C -I -Q "SELECT DB_NAME() AS Db;" -W
if ($LASTEXITCODE -ne 0) {
    throw "Cannot connect to Local SQL."
}
Write-Host "  Local connection OK" -ForegroundColor Green

Write-Host ""
if ($FullSync) {
    Write-Host "Mode: Full DB Sync (-FullSync)" -ForegroundColor Magenta
}
Write-Host "Step 2: Deploy Local SQL scripts..." -ForegroundColor Yellow
if ($SkipSql) {
    Write-Host "  Skipped (-SkipSql)" -ForegroundColor DarkYellow
}
else {
Set-Location $ScriptDir
$localScripts = if ($FullSync) { $FullSyncLocalScripts } else { $SqlScripts }
foreach ($f in $localScripts) {
    $path = Join-Path $ScriptDir $f
    if ($FullSync -and $f -eq "DataSync_11_AllTables_Install.sql") {
        Invoke-SqlFile -Server $LocalServer -Database $LocalDatabase -User $LocalUser -Password $LocalPassword -File $path
        $runPath = Join-Path $ScriptDir "DataSync_11_RunInstall.sql"
        Invoke-SqlFile -Server $LocalServer -Database $LocalDatabase -User $LocalUser -Password $LocalPassword -File $runPath -Vars @{ InstallCapture = 1 }
    }
    else {
        Invoke-SqlFile -Server $LocalServer -Database $LocalDatabase -User $LocalUser -Password $LocalPassword -File $path
    }
}
if ($FullSync -and $SeedOutbox) {
    Write-Host "  Seeding SyncOutbox (missing rows only)..." -ForegroundColor Cyan
    $seedPath = Join-Path $ScriptDir "DataSync_13_InitialSeed.sql"
    Invoke-SqlFile -Server $LocalServer -Database $LocalDatabase -User $LocalUser -Password $LocalPassword -File $seedPath -Vars @{ Reseed = 0 }
}
Write-Host "  Local SQL deploy OK" -ForegroundColor Green
}

if (-not $SkipCloud) {
    if (-not $CloudPassword) {
        $CloudPassword = Read-PlainPassword -Prompt "Enter cloud SQL password"
    }
    Write-Host ""
    Write-Host "Step 3: Deploy Cloud SQL scripts..." -ForegroundColor Yellow
    if ($SkipSql) {
        Write-Host "  Skipped (-SkipSql)" -ForegroundColor DarkYellow
    }
    else {
    try {
        & $sqlcmd -S $CloudServer -d $CloudDatabase -U $CloudUser -P $CloudPassword -C -I -Q "SELECT DB_NAME() AS Db;" -W | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Cloud login failed."
        }
        $cloudScripts = if ($FullSync) { $FullSyncCloudScripts } else { $CloudSqlScripts }
        foreach ($f in $cloudScripts) {
            $path = Join-Path $ScriptDir $f
            if ($FullSync -and $f -eq "DataSync_11_AllTables_Install.sql") {
                Invoke-SqlFile -Server $CloudServer -Database $CloudDatabase -User $CloudUser -Password $CloudPassword -File $path
                $runPath = Join-Path $ScriptDir "DataSync_11_RunInstall.sql"
                Invoke-SqlFile -Server $CloudServer -Database $CloudDatabase -User $CloudUser -Password $CloudPassword -File $runPath -Vars @{ InstallCapture = 0 }
            }
            else {
                Invoke-SqlFile -Server $CloudServer -Database $CloudDatabase -User $CloudUser -Password $CloudPassword -File $path
            }
        }
        Write-Host "  Cloud SQL deploy OK" -ForegroundColor Green
    }
    catch {
        Write-Warning ("Cloud deploy failed: " + $_.Exception.Message)
        Write-Warning "Retry Cloud later with Deploy-CloudSync.cmd"
    }
    }
}
else {
    Write-Host "Step 3: Cloud skipped" -ForegroundColor DarkYellow
}

if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "Step 4: Build SB.SyncAgent..." -ForegroundColor Yellow
    $msbuild = Get-MsBuildPath
    $proj = Join-Path $RepoRoot "SB.SyncAgent\SB.SyncAgent.csproj"
    & $msbuild $proj /p:Configuration=Release /v:minimal /nologo
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed."
    }
    Write-Host "  Build OK" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 5: Copy Sync Agent to ERP folder..." -ForegroundColor Yellow
$erp = Get-ErpFolder -Hint $ErpPath
if (-not $erp) {
    $erp = Read-Host "Enter ERP folder path containing SB.exe"
    if (-not (Test-Path (Join-Path $erp "SB.exe"))) {
        throw ("SB.exe not found in " + $erp)
    }
}

$agentSrc = Join-Path $RepoRoot "SB.SyncAgent\bin\Release\SB.SyncAgent.exe"
if (-not (Test-Path $agentSrc)) {
    $agentSrc = Join-Path $RepoRoot "SB.SyncAgent\bin\Debug\SB.SyncAgent.exe"
}
if (-not (Test-Path $agentSrc)) {
    throw "SB.SyncAgent.exe not built."
}

Copy-Item $agentSrc -Destination $erp -Force
Write-Host ("  Copied to " + $erp) -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Connection ini files..." -ForegroundColor Yellow
Push-Location $erp

$localConn = "Data Source=" + $LocalServer + ";Initial Catalog=" + $LocalDatabase + ";User Id=" + $LocalUser + ";Password=" + $LocalPassword + ";Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"

if (-not (Test-Path "DBConnection.ini")) {
    & ".\SB.SyncAgent.exe" /encrypt DBConnection.ini $localConn
    Write-Host "  Created DBConnection.ini"
}
else {
    Write-Host "  DBConnection.ini already exists"
}

if (-not (Test-Path "CloudConnection.ini")) {
    if (-not $CloudPassword) {
        $CloudPassword = Read-PlainPassword -Prompt "Enter cloud password for CloudConnection.ini"
    }
    $cloudConn = "Data Source=" + $CloudServer + ";Initial Catalog=" + $CloudDatabase + ";User Id=" + $CloudUser + ";Password=" + $CloudPassword + ";Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
    & ".\SB.SyncAgent.exe" /encrypt CloudConnection.ini $cloudConn
    Write-Host "  Created CloudConnection.ini"
}
else {
    Write-Host "  CloudConnection.ini already exists"
}

Write-Host ""
Write-Host "Step 7: Test connections..." -ForegroundColor Yellow
& ".\SB.SyncAgent.exe" /test
if ($LASTEXITCODE -ne 0) {
    throw "Connection test failed."
}

Write-Host ""
Write-Host "Step 8: Test one sync cycle..." -ForegroundColor Yellow
& ".\SB.SyncAgent.exe" /once
Pop-Location

if ($InstallService) {
    Write-Host ""
    Write-Host "Step 9: Install Windows Service..." -ForegroundColor Yellow
    $installUtil = Join-Path $env:windir "Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"
    Push-Location $erp
    & $installUtil /i ".\SB.SyncAgent.exe"
    Start-Service "SB.SyncAgent" -ErrorAction SilentlyContinue
    Pop-Location
    Write-Host "  Service installed and started" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Deploy complete ===" -ForegroundColor Green
Write-Host ("ERP folder: " + $erp)
if ($FullSync) {
    Write-Host ""
    Write-Host "Next on client PC:" -ForegroundColor Yellow
    Write-Host "  1. Monitor: docs\sql\Monitor-SyncProgress.cmd"
    Write-Host "  2. Service: net start SB.SyncAgent  (or install with -InstallService)"
    Write-Host "  3. Fast drain: SB.SyncAgent.exe /drain 480  (~100 rows / 2 sec)"
}
Write-Host ""
