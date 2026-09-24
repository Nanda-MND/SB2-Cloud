# Deploy Account multi-filter SQL to SB1 (fixes GL_ND "too many arguments").
# Run in PowerShell on the PC that can reach SQL Server.

param(
    [string]$ServerInstance = ".\SB1",
    [string]$Database = "SB1",
    [string]$User = "sa",
    [string]$Password = "27042005@MND"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$scripts = @(
    "AccountFilter_Helper.sql",
    "GeneralLedgerDetailReport_ExcludeAddAmount.sql",
    "GL_AccountMultiFilter_Patch.sql"
)

foreach ($s in $scripts) {
    Write-Host "Running $s ..." -ForegroundColor Cyan
    sqlcmd -S $ServerInstance -d $Database -U $User -P $Password -b -i $s
    if ($LASTEXITCODE -ne 0) {
        throw "Failed: $s (exit $LASTEXITCODE)"
    }
}

Write-Host "Done. Re-run Cash/Bank Statement / GL reports." -ForegroundColor Green
