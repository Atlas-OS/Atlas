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

function Get-AtlasConfigurationByteContract {
    param([Parameter(Mandatory = $true)][string]$ConfigurationRoot)

    $root = (Resolve-Path -LiteralPath $ConfigurationRoot).ProviderPath
    Get-ChildItem -LiteralPath $root -Filter '*.yml' -File -Recurse |
        Sort-Object FullName |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($root.Length + 1) -replace '\\', '/'
            $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName))
            '{0}:{1}|{2}' -f $relativePath.Length, $relativePath, $content
        }
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
$archiveIntegrityPassed = $false
try {
    Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList (@('t', '-bso0', '-bsp0') + $passwordArgs + @($Path)) -ErrorContext 'Archive integrity test' | Out-Null
    $archiveIntegrityPassed = $true
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
$archivePathsSafe = $false
$canExtractArchive = $false

if ($entryPaths.Count -eq 0) {
    Add-Failure 'Archive listing returned no entries.'
}
else {
    $unsafePaths = @($entryPaths | Where-Object {
            [IO.Path]::IsPathRooted($_) -or (($_ -split '/') -contains '..')
        })
    $duplicateArchivePaths = @($entryPaths | Group-Object -CaseSensitive |
            Where-Object Count -gt 1 | ForEach-Object Name)
    if ($unsafePaths) {
        Add-Failure "Archive contains rooted or parent-traversal paths: $($unsafePaths -join ', ')"
    }
    else {
        Write-Pass 'All archive entry paths are relative and traversal-free.'
    }
    if ($duplicateArchivePaths) {
        Add-Failure "Archive listing contains duplicate entry paths: $($duplicateArchivePaths -join ', ')"
    }
    else {
        Write-Pass 'Archive entry paths are unique.'
    }
    $archivePathsSafe = ($unsafePaths.Count -eq 0 -and $duplicateArchivePaths.Count -eq 0)

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
            $canExtractArchive = $archiveIntegrityPassed -and $archivePathsSafe
            Write-Pass "Exact source/archive payload path parity ($($expectedPayloadPaths.Count) files)."
        }
    }
    catch {
        Add-Failure "Payload parity validation failed: $($_.Exception.Message)"
    }
}

# 4-6. Extract and verify generated configuration, metadata, and the OEM stamp.
if (-not $canExtractArchive) {
    Add-Failure (
        'Archive extraction was blocked because integrity, path safety, uniqueness, and ' +
        'exact payload parity were not all established.'
    )
}
else {
    $extractDir = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    try {
    $extractArgs = @('e', "-o$extractDir", '-y', '-r', '-bso0', '-bsp0') + $passwordArgs + @($Path, 'playbook.conf', 'Set-OemInformation.ps1')
    Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $extractArgs -ErrorContext 'Extracting verification files' | Out-Null

    # 4. The archive's generated configuration must retain the reviewed runner boundary.
    # Extract with paths preserved so every configuration byte, including custom.yml, can
    # be compared with the source. Content-removal profiles are not valid install plans.
    try {
        $configurationPaths = @($entryPaths | Where-Object {
                $_ -match '^Configuration/.+\.yml$'
            })
        if ($configurationPaths.Count -eq 0) {
            throw 'Archive listing contains no YAML configuration files.'
        }
        $configurationExtractArgs = @(
            'x', "-o$extractDir", '-y', '-r', '-bso0', '-bsp0'
        ) + $passwordArgs + @($Path) + $configurationPaths
        Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $configurationExtractArgs `
            -ErrorContext 'Extracting runner configuration' | Out-Null

        $extractedConfigurationRoot = Join-Path -Path $extractDir -ChildPath 'Configuration'
        $runnerSummary = Assert-AtlasConfigurationRunnerBoundary `
            -ConfigurationRoot $extractedConfigurationRoot
        Write-Pass (
            'Archive runner boundary ({0} actions, {1} checked PowerShell runs).' -f `
                $runnerSummary.Actions, $runnerSummary.Runs
        )
        if ($runnerSummary.RequiresTrustedRunnerEnvironment) {
            Write-Warning (
                'The YAML contract cannot authenticate the inherited process environment: ' +
                'RunAction expands %SystemRoot% before launch, and managed-runtime startup, ' +
                'profiling, JIT, and AppDomain variables act before script entry. The upstream ' +
                'AME runner must construct the complete trusted environment before process creation.'
            )
        }

        $sourceConfigurationRoot = Join-Path -Path $PlaybookPath -ChildPath 'Configuration'
        $sourceConfigurationContract = @(Get-AtlasConfigurationByteContract `
                -ConfigurationRoot $sourceConfigurationRoot)
        $archiveConfigurationContract = @(Get-AtlasConfigurationByteContract `
                -ConfigurationRoot $extractedConfigurationRoot)
        $configurationDifference = @(Compare-Object `
                -ReferenceObject $sourceConfigurationContract `
                -DifferenceObject $archiveConfigurationContract `
                -CaseSensitive)
        if ($configurationDifference.Count -gt 0) {
            $firstDifference = $configurationDifference[0]
            throw (
                'Archive configuration differs from the reviewed source configuration: ' +
                "[$($firstDifference.SideIndicator)] $($firstDifference.InputObject)"
            )
        }
        Write-Pass 'Every archive configuration byte matches the reviewed source.'

        $expectedRunnerContract = @(Get-AtlasConfigurationRunnerContract `
                -ConfigurationRoot $sourceConfigurationRoot)
        $archiveRunnerContract = @(Get-AtlasConfigurationRunnerContract `
                -ConfigurationRoot $extractedConfigurationRoot)
        $runnerContractDifference = @(Compare-Object `
                -ReferenceObject @($expectedRunnerContract.Signature) `
                -DifferenceObject @($archiveRunnerContract.Signature) `
                -CaseSensitive)
        if ($runnerContractDifference.Count -gt 0) {
            $firstDifference = $runnerContractDifference[0]
            throw (
                'Archive runner contract differs from the reviewed source configuration: ' +
                "[$($firstDifference.SideIndicator)] $($firstDifference.InputObject)"
            )
        }
        Write-Pass 'Archive runner order and action-local contracts match the reviewed source.'

        $expectedCustomYml = Join-Path -Path $sourceConfigurationRoot -ChildPath 'custom.yml'
        $archiveCustomYml = Join-Path -Path $extractedConfigurationRoot -ChildPath 'custom.yml'
        if (-not (Test-Path -LiteralPath $expectedCustomYml -PathType Leaf) -or
            -not (Test-Path -LiteralPath $archiveCustomYml -PathType Leaf)) {
            throw 'Expected-profile or archive custom.yml is missing.'
        }
        $expectedCustomBytes = [Convert]::ToBase64String([IO.File]::ReadAllBytes($expectedCustomYml))
        $archiveCustomBytes = [Convert]::ToBase64String([IO.File]::ReadAllBytes($archiveCustomYml))
        if ($expectedCustomBytes -cne $archiveCustomBytes) {
            throw 'Archive custom.yml differs from the reviewed source configuration.'
        }
        Write-Pass 'Archive custom.yml is byte-identical to the reviewed source.'
    }
    catch {
        Add-Failure "Archive runner-boundary validation failed: $($_.Exception.Message)"
    }

    # 5. playbook.conf parses and carries consistent version metadata.
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

    # 6. OEM version placeholder must be stamped out by the build.
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
}

if ($failures.Count -gt 0) {
    Write-Host "`n$($failures.Count) check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nAll apbx checks passed." -ForegroundColor Green
exit 0
