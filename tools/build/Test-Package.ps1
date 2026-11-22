<#
.SYNOPSIS
    Verifies a built Atlas package (.atlaspkg): archive integrity, encryption, safe and
    exact file paths, the root layout, the manifest and the stamped OEM version.
.DESCRIPTION
    Checks what can be checked without installing the package. The manifest must follow
    docs/package-format.md, and every option image must be in the package's Images/.
.PARAMETER Path
    The .atlaspkg file to verify.
.PARAMETER NoPassword
    Expects an archive built with -NoPassword, whose entries aren't encrypted. Without it,
    every file in the archive must be encrypted with AES-256 under the public password.
.PARAMETER PackagePath
    The package source folder the archive must match file for file. The default is the
    repository's package/ folder.
.NOTES
    Exit codes: 0 when every check passes, 1 otherwise.
#>
#requires -Version 7.0
Param(
    [Parameter(Mandatory = $true)][string]$Path,
    [switch]$NoPassword,
    [string]$PackagePath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'AtlasBuild\AtlasBuild.psd1') -Force

if (-not $PackagePath) {
    $PackagePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\package'
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

function Format-PathList {
    # Names the first few paths of a long list, so a failure stays readable.
    param([Parameter(Mandatory = $true)][string[]]$Path)
    $shown = @($Path | Select-Object -First 10) -join ', '
    if ($Path.Count -gt 10) {
        $shown += " and $($Path.Count - 10) more"
    }
    return $shown
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

function Get-RecordValue {
    param([Parameter(Mandatory = $true)]$Record, [Parameter(Mandatory = $true)][string]$Name)
    $property = $Record.PSObject.Properties[$Name]
    if ($property) { return [string]$property.Value }
    return ''
}


if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Host "FAIL: package not found at '$Path'." -ForegroundColor Red
    exit 1
}

$Path = (Resolve-Path -LiteralPath $Path).ProviderPath
$sevenZipPath = Resolve-SevenZip
# Always passed: 7-Zip ignores a password for entries that aren't encrypted, and without
# one it would wait for a password on the console. The encryption check below decides
# whether the archive is encrypted as expected.
$passwordArgs = @("-p$(Get-AtlasPackagePassword)")

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
$expectedRootDirs = @('Executables', 'Images')
$expectedRootFiles = @('atlas.json')

$listOutput = Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList (@('l', '-ba', '-slt') + $passwordArgs + @($Path)) -ErrorContext 'Archive listing'
$archiveEntries = @(ConvertFrom-SevenZipTechnicalList -Line @($listOutput | ForEach-Object { "$_" }))
$entryPaths = @($archiveEntries | ForEach-Object { $_.Path.Replace('\', '/') })
$fileEntries = @($archiveEntries | Where-Object { (Get-RecordValue -Record $_ -Name 'Folder') -eq '-' })
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

    foreach ($required in @('atlas.json', 'Executables')) {
        if ($rootEntries -notcontains $required) {
            Add-Failure "Required root entry missing: $required"
        }
    }

    $leaked = @($entryPaths | Where-Object { $_ -match '\.atlaspkg($|\.)|(^|/)(Build|Test)-Package\.ps1$' })
    if ($leaked) {
        Add-Failure "Build output or tooling leaked into the archive: $($leaked -join ', ')"
    }
    else {
        Write-Pass 'No build output or tooling inside the archive.'
    }
}

# 3. Encryption: every file is protected with AES-256 unless the build had -NoPassword.
if ($fileEntries.Count -gt 0) {
    if ($NoPassword) {
        $encrypted = @($fileEntries | Where-Object { (Get-RecordValue -Record $_ -Name 'Encrypted') -eq '+' } |
                ForEach-Object { $_.Path.Replace('\', '/') })
        if ($encrypted) {
            Add-Failure "Encrypted files in an archive expected without a password: $(Format-PathList -Path $encrypted)"
        }
        else {
            Write-Pass "No file is encrypted, as -NoPassword expects ($($fileEntries.Count) files)."
        }
    }
    else {
        $unprotected = @($fileEntries | Where-Object {
                (Get-RecordValue -Record $_ -Name 'Encrypted') -ne '+' -or
                (Get-RecordValue -Record $_ -Name 'Method') -notmatch '(^|\s)AES-256(\s|$)'
            } | ForEach-Object { $_.Path.Replace('\', '/') })
        if ($unprotected) {
            Add-Failure "Files not encrypted with AES-256: $(Format-PathList -Path $unprotected)"
        }
        else {
            Write-Pass "Every file is encrypted with AES-256 ($($fileEntries.Count) files)."
        }
    }
}

# 4. Exact file-list parity: every source file must appear exactly once, and no
# untracked or stale file may hide below an otherwise allowed root directory. Staged
# test-build overrides change content but never the path set, so path parity applies to
# both release and local-test builds.
$actualFilePaths = @($fileEntries | ForEach-Object { $_.Path.Replace('\', '/') })
if (-not (Test-Path -LiteralPath $PackagePath -PathType Container)) {
    Add-Failure "Package source folder not found at '$PackagePath'; file parity could not be checked."
}
else {
    try {
        $expectedFilePaths = @(Get-AtlasPackageFilePath -PackagePath $PackagePath)
        $fileComparison = Compare-AtlasPackageFilePath -ExpectedPath $expectedFilePaths -ActualPath $actualFilePaths

        if ($fileComparison.Missing) {
            Add-Failure "Source files missing from the archive: $($fileComparison.Missing -join ', ')"
        }
        if ($fileComparison.Unexpected) {
            Add-Failure "Unexpected files present in the archive: $($fileComparison.Unexpected -join ', ')"
        }
        if ($fileComparison.Duplicates) {
            Add-Failure "Archive contains duplicate file paths: $($fileComparison.Duplicates -join ', ')"
        }
        if ($fileComparison.Matches) {
            $canExtractArchive = $archiveIntegrityPassed -and $archivePathsSafe
            Write-Pass "Exact source/archive file path parity ($($expectedFilePaths.Count) files)."
        }
    }
    catch {
        Add-Failure "File parity validation failed: $($_.Exception.Message)"
    }
}

# 5-6. Extract and verify the manifest and the OEM stamp.
if (-not $canExtractArchive) {
    Add-Failure (
        'Archive extraction was blocked because integrity, path safety, uniqueness, and ' +
        'exact file parity were not all established.'
    )
}
else {
    $extractDir = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    $oemRelativePath = 'Executables/AtlasModules/Scripts/Install/Tasks/Set-OemInformation.ps1'
    try {
        # Exact paths without recursion, so a file of the same name elsewhere can't stand in.
        $extractArgs = @('x', "-o$extractDir", '-y', '-r-', '-bso0', '-bsp0') + $passwordArgs +
            @($Path, 'atlas.json', $oemRelativePath)
        Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $extractArgs -ErrorContext 'Extracting verification files' | Out-Null

        # 5. atlas.json parses and follows the package format.
        $manifestPath = Join-Path -Path $extractDir -ChildPath 'atlas.json'
        $versionInfo = $null
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            $manifestProblems = @(Test-AtlasManifest -Path $manifestPath -PackageFile $actualFilePaths)
            if ($manifestProblems) {
                foreach ($problem in $manifestProblems) {
                    Add-Failure "atlas.json: $problem"
                }
            }
            else {
                $versionInfo = Get-AtlasPackageVersion -ManifestPath $manifestPath
                Write-Pass "atlas.json follows the package format (version $($versionInfo.Version))."
                $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if (@($manifest.supportedBuilds).Count -eq 0) {
                    Write-Host 'NOTE: atlas.json lists no supportedBuilds, so the front door refuses to install this test build.'
                }
                if (@($manifest.requirements).Count -eq 0) {
                    Write-Host 'NOTE: atlas.json lists no requirements, so the front door runs only the checks it always runs.'
                }
            }
        }
        else {
            Add-Failure 'atlas.json could not be extracted from the archive.'
        }

        # 6. The build must stamp the version over the OEM placeholder.
        $oemPath = Join-Path -Path $extractDir -ChildPath $oemRelativePath
        if (Test-Path -LiteralPath $oemPath -PathType Leaf) {
            $oemContent = [string](Get-Content -LiteralPath $oemPath -Raw)
            if ($oemContent -match 'AtlasVersionUndefined') {
                Add-Failure 'Set-OemInformation.ps1 still contains the AtlasVersionUndefined placeholder.'
            }
            elseif ($versionInfo -and -not $oemContent.Contains($versionInfo.VersionLabel)) {
                Add-Failure "Set-OemInformation.ps1 doesn't carry the version label $($versionInfo.VersionLabel)."
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

Write-Host "`nAll package checks passed." -ForegroundColor Green
exit 0
