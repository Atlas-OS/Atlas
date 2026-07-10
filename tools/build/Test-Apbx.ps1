<#
.SYNOPSIS
    Verifies a built .apbx package: archive integrity, exact payload file parity, safe
    paths, expected root layout, metadata, and a stamped OEM version.
.DESCRIPTION
    The strongest end-to-end signal available without applying the playbook to a live
    Windows install. Exits 0 when all checks pass, 1 otherwise.
#>
#requires -Version 7.0
# The apbx archive password is public by design (documented in README.md); it exists so
# antivirus engines don't scan-flag the payload, not for secrecy.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
Param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Password = 'malte',
    [string]$PlaybookPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'AtlasBuild\AtlasBuild.psd1') -Force

if (-not $PlaybookPath) {
    $PlaybookPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\playbook'
}

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function ConvertFrom-SevenZipTechnicalList {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Line
    )

    $records = [System.Collections.Generic.List[object]]::new()
    $record = @{}

    foreach ($currentLine in $Line) {
        if ([string]::IsNullOrWhiteSpace($currentLine)) {
            if ($record.ContainsKey('Path')) {
                $records.Add([pscustomobject]$record)
            }
            $record = @{}
            continue
        }

        if ($currentLine -match '^([^=]+) = (.*)$') {
            $record[$matches[1].Trim()] = $matches[2]
        }
    }

    if ($record.ContainsKey('Path')) {
        $records.Add([pscustomobject]$record)
    }

    return $records.ToArray()
}

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Host "FAIL: apbx not found at '$Path'." -ForegroundColor Red
    exit 1
}

$Path = (Resolve-Path -LiteralPath $Path).ProviderPath
$sevenZipPath = Resolve-SevenZip
$passwordArgs = @()
if ($Password) {
    $passwordArgs += "-p$Password"
}

# 1. Archive integrity (also proves the password is correct).
try {
    Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList (@('t', '-bso0', '-bsp0') + $passwordArgs + @($Path)) -ErrorContext 'Archive integrity test' | Out-Null
    Write-Pass 'Archive integrity and password.'
}
catch {
    Add-Failure "Archive integrity test failed: $($_.Exception.Message)"
}

# 2. Root layout: only expected entries at the archive root, no leaked tooling.
$expectedRootDirs = @('Configuration', 'Executables', 'Images')
$expectedRootFiles = @('playbook.conf', 'playbook.png')

$listOutput = Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList (@('l', '-ba', '-slt') + $passwordArgs + @($Path)) -ErrorContext 'Archive listing'
$archiveEntries = @(ConvertFrom-SevenZipTechnicalList -Line @($listOutput | ForEach-Object { "$_" }))
$entryPaths = @($archiveEntries | ForEach-Object { $_.Path.Replace('\', '/') })

if ($entryPaths.Count -eq 0) {
    Add-Failure 'Archive listing returned no entries.'
}
else {
    $unsafePaths = @($entryPaths | Where-Object {
            [IO.Path]::IsPathRooted($_) -or (($_ -split '/') -contains '..')
        })
    if ($unsafePaths) {
        Add-Failure "Archive contains rooted or parent-traversal paths: $($unsafePaths -join ', ')"
    }
    else {
        Write-Pass 'All archive entry paths are relative and traversal-free.'
    }

    $rootEntries = $entryPaths | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique
    $unexpectedRoots = @($rootEntries | Where-Object { ($expectedRootDirs -notcontains $_) -and ($expectedRootFiles -notcontains $_) })

    if ($unexpectedRoots) {
        Add-Failure "Unexpected entries at archive root: $($unexpectedRoots -join ', ')"
    }
    else {
        Write-Pass "Archive root layout ($($rootEntries -join ', '))."
    }

    foreach ($required in @('playbook.conf', 'Configuration', 'Executables')) {
        if ($rootEntries -notcontains $required) {
            Add-Failure "Required root entry missing: $required"
        }
    }

    $leaked = @($entryPaths | Where-Object { $_ -match '\.apbx$|build-playbook|Build-Playbook\.ps1|local-build' })
    if ($leaked) {
        Add-Failure "Build tooling leaked into the archive: $($leaked -join ', ')"
    }
    else {
        Write-Pass 'No build tooling inside the archive.'
    }
}

# 3. Exact file-list parity: every source payload file must ship exactly once, and no
# untracked/stale file may hide below an otherwise allowed root directory. Staged dev-build
# overrides intentionally change content but never the path set, so path parity applies to
# both release and local-test builds.
if (-not (Test-Path -LiteralPath $PlaybookPath -PathType Container)) {
    Add-Failure "Source playbook directory not found at '$PlaybookPath'; payload parity could not be checked."
}
else {
    try {
        $expectedPayloadPaths = @(Get-AtlasPlaybookPayloadPath -PlaybookPath $PlaybookPath)
        $actualPayloadPaths = @($archiveEntries |
            Where-Object { $_.PSObject.Properties['Folder'] -and $_.Folder -eq '-' } |
            ForEach-Object { $_.Path })
        $payloadComparison = Compare-AtlasPayloadPath -ExpectedPath $expectedPayloadPaths -ActualPath $actualPayloadPaths

        if ($payloadComparison.Missing) {
            Add-Failure "Payload files missing from the archive: $($payloadComparison.Missing -join ', ')"
        }
        if ($payloadComparison.Unexpected) {
            Add-Failure "Unexpected files present in the archive: $($payloadComparison.Unexpected -join ', ')"
        }
        if ($payloadComparison.Duplicates) {
            Add-Failure "Archive contains duplicate file paths: $($payloadComparison.Duplicates -join ', ')"
        }
        if ($payloadComparison.Matches) {
            Write-Pass "Exact source/archive payload path parity ($($expectedPayloadPaths.Count) files)."
        }
    }
    catch {
        Add-Failure "Payload parity validation failed: $($_.Exception.Message)"
    }
}

# 4. playbook.conf parses and carries consistent version metadata.
$extractDir = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid().Guid)
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
try {
    $extractArgs = @('e', "-o$extractDir", '-y', '-r', '-bso0', '-bsp0') + $passwordArgs + @($Path, 'playbook.conf', 'Set-OemInformation.ps1')
    Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $extractArgs -ErrorContext 'Extracting verification files' | Out-Null

    $confPath = Join-Path -Path $extractDir -ChildPath 'playbook.conf'
    if (Test-Path -LiteralPath $confPath -PathType Leaf) {
        try {
            $versionInfo = Get-PlaybookVersion -PlaybookConfPath $confPath
            Write-Pass "playbook.conf parses (version $($versionInfo.Version))."

            if ($versionInfo.Title -notmatch [regex]::Escape("v$($versionInfo.Version)")) {
                Add-Failure "playbook.conf <Title> '$($versionInfo.Title)' does not contain 'v$($versionInfo.Version)'."
            }
            else {
                Write-Pass 'playbook.conf Title/Version consistency.'
            }
        }
        catch {
            Add-Failure "playbook.conf validation failed: $($_.Exception.Message)"
        }
    }
    else {
        Add-Failure 'playbook.conf could not be extracted from the archive.'
    }

    # 5. OEM version placeholder must be stamped out by the build.
    $oemPath = Join-Path -Path $extractDir -ChildPath 'Set-OemInformation.ps1'
    if (Test-Path -LiteralPath $oemPath -PathType Leaf) {
        $oemContent = Get-Content -Path $oemPath -Raw
        if ($oemContent -match 'AtlasVersionUndefined') {
            Add-Failure 'Set-OemInformation.ps1 still contains the AtlasVersionUndefined placeholder.'
        }
        else {
            Write-Pass 'OEM version stamped.'
        }
    }
    else {
        Add-Failure 'Set-OemInformation.ps1 could not be extracted from the archive.'
    }
}
finally {
    Remove-Item -LiteralPath $extractDir -Force -Recurse -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    Write-Host "`n$($failures.Count) check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nAll apbx checks passed." -ForegroundColor Green
exit 0
