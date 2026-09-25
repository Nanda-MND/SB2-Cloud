# Shared Dev/Test guards for SB2-Cloud runners.
# Dot-source this file. It does not connect to SQL.

$script:Sb2ForbiddenServerPattern = '(?i)(sql1002\.site4now\.net|site4now\.net|sql1002)'
$script:Sb2ForbiddenDatabases = @('SB1', 'SB', 'db_abbe78_warehouse')
$script:Sb2ForbiddenUsers = @('db_abbe78_warehouse_admin')
$script:Sb2DevServiceName = 'SB2.SyncAgent.Dev'
$script:Sb2DevErpFolder = 'D:\Dev\SB2-Cloud\'

function Assert-Sb2SqlIdentifier {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if ($Name -notmatch '^[A-Za-z0-9_]+$') {
        throw "$Label must be a simple SQL identifier (letters, digits, underscore). Refusing '$Name'."
    }
}

function Assert-Sb2ServerToken {
    param([Parameter(Mandatory = $true)][string]$Server)
    if ($Server -notmatch '^[A-Za-z0-9_.\\,:()-]+$') {
        throw "Server name contains characters this runner will not pass to sqlcmd."
    }
}

function Assert-Sb2DevTestTarget {
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [Parameter(Mandatory = $true)][string]$Database,
        [string]$User = '',
        [ValidateSet('Local', 'TestCloud')][string]$Role = 'Local'
    )

    if ([string]::IsNullOrWhiteSpace($Server) -or [string]::IsNullOrWhiteSpace($Database)) {
        throw 'Server and Database are required.'
    }

    Assert-Sb2ServerToken -Server $Server
    Assert-Sb2SqlIdentifier -Name $Database -Label 'Database'

    if ($Server -match $script:Sb2ForbiddenServerPattern) {
        throw "Refusing production cloud host '$Server'. This phase allows Dev Local and Test Cloud only."
    }

    foreach ($forbidden in $script:Sb2ForbiddenDatabases) {
        if ([string]::Equals($Database, $forbidden, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing database '$Database'. SB1 and the production cloud catalog are not allowed in this phase."
        }
    }

    if ($Database -match '(?i)abbe78') {
        throw "Refusing production cloud database name '$Database'."
    }

    if ($Server -match '(?i)(^|\\)SB1($|\\)') {
        throw "Refusing SB1 instance in server name '$Server'."
    }

    if (-not [string]::IsNullOrWhiteSpace($User)) {
        foreach ($forbiddenUser in $script:Sb2ForbiddenUsers) {
            if ([string]::Equals($User, $forbiddenUser, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Refusing production cloud login '$User'."
            }
        }
    }

    if ($Role -eq 'Local') {
        if ($Database -match '(?i)warehouse' -or $Database -match '(?i)abbe') {
            throw "Refusing to run Dev Local scripts on a cloud/warehouse database '$Database'."
        }
    }
}

function Assert-Sb2NotDevLocalServer {
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [Parameter(Mandatory = $true)][string]$Database,
        [string]$DevLocalServer = '',
        [string]$DevLocalDatabase = ''
    )

    if ([string]::IsNullOrWhiteSpace($DevLocalServer)) {
        return
    }

    $sameServer = [string]::Equals($Server, $DevLocalServer, [StringComparison]::OrdinalIgnoreCase)
    $sameDatabase = [string]::IsNullOrWhiteSpace($DevLocalDatabase) -or
        [string]::Equals($Database, $DevLocalDatabase, [StringComparison]::OrdinalIgnoreCase)
    if ($sameServer -and $sameDatabase) {
        throw 'Refusing to run Test Cloud restore/scripts on the Dev Local target. Pass the Test Cloud host.'
    }
}

function Assert-Sb2ResolvedEndpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [Parameter(Mandatory = $true)][string]$Database,
        [string]$User = ''
    )

    foreach ($value in @($Server, $Database, $User)) {
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        if ($value -match '(?i)YOUR_|PLACEHOLDER|\*\*\*') {
            throw "Refusing unresolved placeholder '$value'. Supply the Dev/Test value at runtime. Do not commit it."
        }
    }
}

function Assert-Sb2ConnectionText {
    param([Parameter(Mandatory = $true)][string]$ConnectionText)

    $catalogSb1 = [regex]::IsMatch($ConnectionText, 'Initial\s+Catalog\s*=\s*SB1\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $catalogSb = [regex]::IsMatch($ConnectionText, 'Initial\s+Catalog\s*=\s*SB(?![A-Za-z0-9_])', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $databaseSb1 = [regex]::IsMatch($ConnectionText, 'Database\s*=\s*SB1\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($catalogSb1 -or $catalogSb -or $databaseSb1) {
        throw 'Refusing SB1 or live SB catalog in a connection string.'
    }
    if ($ConnectionText -match '(?i)site4now|sql1002|db_abbe78') {
        throw 'Refusing production cloud host or catalog in a connection string.'
    }
}

function Assert-Sb2DevErpFolder {
    param([Parameter(Mandatory = $true)][string]$ErpFolder)

    if ($ErpFolder -match '(?i)MinnNandar|site4now|\\Client PC\\') {
        throw "Refusing live/client ERP folder '$ErpFolder'. Use $script:Sb2DevErpFolder."
    }
    if (Test-Path -LiteralPath (Join-Path $ErpFolder '.git')) {
        throw 'Refusing to write DBConnection.ini / CloudConnection.ini inside a git checkout.'
    }
}

function Get-Sb2SqlCmd {
    $cmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$env:ProgramFiles\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE",
        "${env:ProgramFiles(x86)}\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE",
        "$env:ProgramFiles\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE"
    )
    foreach ($path in $candidates) {
        if ($path -and (Test-Path -LiteralPath $path)) { return $path }
    }
    throw 'sqlcmd not found. Install SQL Server command-line tools on the Dev PC.'
}

function Get-Sb2RepoRoot {
    param([Parameter(Mandatory = $true)][string]$StartPath)
    $dir = Resolve-Path -LiteralPath $StartPath
    while ($dir) {
        if (Test-Path -LiteralPath (Join-Path $dir.Path '.git')) {
            return $dir.Path
        }
        $parent = Split-Path -Parent $dir.Path
        if (-not $parent -or $parent -eq $dir.Path) { break }
        $dir = Resolve-Path -LiteralPath $parent
    }
    throw 'Could not locate the SB2-Cloud repo root.'
}

function New-Sb2SqlConnectionString {
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [Parameter(Mandatory = $true)][string]$Database,
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Password
    )

    Assert-Sb2ConnectionText -ConnectionText ("Data Source=" + $Server + ";Initial Catalog=" + $Database + ";User Id=" + $User + ";")
    return "Data Source=$Server;Initial Catalog=$Database;User Id=$User;Password=$Password;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
}

function Invoke-Sb2SqlFile {
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [Parameter(Mandatory = $true)][string]$Database,
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][string]$File,
        [hashtable]$Variables
    )

    if (-not (Test-Path -LiteralPath $File)) {
        throw "Missing SQL file: $File"
    }

    $sqlcmd = Get-Sb2SqlCmd
    $argList = @('-S', $Server, '-d', $Database, '-U', $User, '-P', $Password, '-C', '-I', '-b', '-i', $File)
    if ($Variables) {
        foreach ($key in @($Variables.Keys)) {
            $argList += @('-v', ($key + '=' + $Variables[$key]))
        }
    }

    Write-Host ("SQL " + (Split-Path -Leaf $File))
    & $sqlcmd @argList
    if ($LASTEXITCODE -ne 0) {
        throw ("sqlcmd failed for " + (Split-Path -Leaf $File) + " (exit " + $LASTEXITCODE + ").")
    }
}

function Invoke-Sb2SqlFiles {
    param(
        [Parameter(Mandatory = $true)][string]$Server,
        [Parameter(Mandatory = $true)][string]$Database,
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][string]$SqlDir,
        [Parameter(Mandatory = $true)][string[]]$Files,
        [hashtable]$Variables
    )

    foreach ($name in $Files) {
        $path = Join-Path $SqlDir $name
        Invoke-Sb2SqlFile -Server $Server -Database $Database -User $User -Password $Password -File $path -Variables $Variables
    }
}
