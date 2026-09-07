# Transactional publication for the pinned Open-Shell theme payload.

function Get-AtlasOpenShellThemeFileSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
}

function Assert-AtlasOpenShellThemeDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Description
    )

    if (-not [IO.Directory]::Exists($Path)) {
        throw "$Description directory is missing at '$Path'."
    }
}

function Assert-AtlasOpenShellThemeFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][long]$ExpectedBytes,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    if (-not [IO.File]::Exists($Path)) {
        throw "The required Open-Shell theme file is missing at '$Path'."
    }
    if ((Get-Item -LiteralPath $Path -Force -ErrorAction Stop).Length -ne $ExpectedBytes) {
        throw "The Open-Shell theme file '$Path' failed its length check."
    }
    if (-not (Get-AtlasOpenShellThemeFileSha256 -Path $Path).Equals(
            $ExpectedSha256,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "The Open-Shell theme file '$Path' failed its SHA-256 check."
    }
}

function Test-AtlasOpenShellThemeExpectedFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][long]$ExpectedBytes,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    if (-not [IO.File]::Exists($Path)) { return $false }
    $file = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($file.Length -ne $ExpectedBytes) { return $false }
    return (Get-AtlasOpenShellThemeFileSha256 -Path $Path).Equals(
        $ExpectedSha256,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Assert-AtlasOpenShellThemeReplaceableFile {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([IO.Directory]::Exists($Path)) {
        throw "The Open-Shell theme target '$Path' is a directory."
    }
    if ([IO.File]::Exists($Path) -and
        -not (Test-AtlasProtectedExecutionAcl -Acl (
                Get-Acl -LiteralPath $Path -ErrorAction Stop
            ))) {
        throw "The Open-Shell theme target '$Path' has an untrusted owner or writable principal."
    }
}

function Invoke-AtlasOpenShellThemeFileTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SourceDirectory,
        [Parameter(Mandatory = $true)][string]$SkinsDirectory,
        [Parameter(Mandatory = $true)][object[]]$ExpectedFiles
    )

    Assert-AtlasOpenShellThemeDirectory -Path $SourceDirectory -Description 'Extracted theme'
    Assert-AtlasOpenShellThemeDirectory -Path $SkinsDirectory -Description 'Open-Shell skins'

    $sourceItems = @(Get-ChildItem -LiteralPath $SourceDirectory -Force -ErrorAction Stop)
    if ($sourceItems.Count -ne $ExpectedFiles.Count) {
        throw 'The extracted Open-Shell theme payload contains an unexpected number of entries.'
    }

    $expectedNames = @{}
    foreach ($expected in $ExpectedFiles) {
        $name = [string]$expected.Name
        $key = $name.ToUpperInvariant()
        if ([string]::IsNullOrWhiteSpace($name) -or
            $name -ne [IO.Path]::GetFileName($name) -or
            $expectedNames.ContainsKey($key)) {
            throw "The Open-Shell theme manifest contains an invalid or duplicate file name '$name'."
        }
        $expectedNames[$key] = $true
        Assert-AtlasOpenShellThemeFile `
            -Path (Join-Path -Path $SourceDirectory -ChildPath $name) `
            -ExpectedBytes ([long]$expected.Length) `
            -ExpectedSha256 ([string]$expected.Sha256)
    }
    foreach ($sourceItem in $sourceItems) {
        if ($sourceItem.PSIsContainer -or
            -not $expectedNames.ContainsKey($sourceItem.Name.ToUpperInvariant())) {
            throw "The extracted Open-Shell theme payload contains unexpected entry '$($sourceItem.Name)'."
        }
    }

    $transactionId = [guid]::NewGuid().ToString('N')
    $records = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($expected in $ExpectedFiles) {
            $name = [string]$expected.Name
            $length = [long]$expected.Length
            $sha256 = [string]$expected.Sha256
            $sourcePath = Join-Path -Path $SourceDirectory -ChildPath $name
            $targetPath = Join-Path -Path $SkinsDirectory -ChildPath $name

            if (Test-AtlasOpenShellThemeExpectedFile `
                    -Path $targetPath `
                    -ExpectedBytes $length `
                    -ExpectedSha256 $sha256) {
                continue
            }

            Assert-AtlasOpenShellThemeReplaceableFile -Path $targetPath
            $targetExisted = [IO.File]::Exists($targetPath)
            $candidatePath = "$targetPath.atlas-$transactionId.new"
            $backupPath = "$targetPath.atlas-$transactionId.bak"
            $record = [pscustomobject]@{
                Name          = $name
                Target        = $targetPath
                Candidate     = $candidatePath
                Backup        = $backupPath
                TargetExisted = $targetExisted
                Length        = $length
                Sha256        = $sha256
            }
            $records.Add($record)

            [IO.File]::Copy($sourcePath, $candidatePath, $false)
            Assert-AtlasOpenShellThemeFile `
                -Path $candidatePath `
                -ExpectedBytes $length `
                -ExpectedSha256 $sha256

            if ($targetExisted) {
                [IO.File]::Replace($candidatePath, $targetPath, $backupPath)
            }
            else {
                [IO.File]::Move($candidatePath, $targetPath)
            }
            Assert-AtlasOpenShellThemeFile `
                -Path $targetPath `
                -ExpectedBytes $length `
                -ExpectedSha256 $sha256
        }
    }
    catch {
        $originalFailure = $_.Exception.Message
        $rollbackFailures = New-Object System.Collections.Generic.List[string]
        for ($index = $records.Count - 1; $index -ge 0; $index--) {
            $record = $records[$index]
            try {
                $published = Test-AtlasOpenShellThemeExpectedFile `
                    -Path $record.Target `
                    -ExpectedBytes $record.Length `
                    -ExpectedSha256 $record.Sha256
                if ($published) {
                    if ($record.TargetExisted) {
                        if (-not [IO.File]::Exists($record.Backup)) {
                            throw 'the original target backup is missing'
                        }
                        [IO.File]::Replace(
                            $record.Backup,
                            $record.Target,
                            $record.Candidate
                        )
                    }
                    else {
                        [IO.File]::Delete($record.Target)
                    }
                }
                elseif ([IO.File]::Exists($record.Backup)) {
                    throw 'the target changed after publication; its backup was retained'
                }
                elseif (-not $record.TargetExisted -and
                    ([IO.File]::Exists($record.Target) -or
                        [IO.Directory]::Exists($record.Target))) {
                    throw 'a first-install target now contains unknown data'
                }

                if ([IO.File]::Exists($record.Candidate)) {
                    [IO.File]::Delete($record.Candidate)
                }
            }
            catch {
                $rollbackFailures.Add("$($record.Name): $($_.Exception.Message)")
            }
        }
        if ($rollbackFailures.Count -ne 0) {
            throw "Open-Shell theme publication failed: $originalFailure; rollback was incomplete: $($rollbackFailures -join '; ')."
        }
        throw "Open-Shell theme publication failed and was rolled back: $originalFailure"
    }

    $cleanupFailures = New-Object System.Collections.Generic.List[string]
    foreach ($record in $records) {
        foreach ($artifact in @($record.Candidate, $record.Backup)) {
            if (-not [IO.File]::Exists($artifact)) { continue }
            try {
                [IO.File]::Delete($artifact)
            }
            catch {
                $cleanupFailures.Add("${artifact}: $($_.Exception.Message)")
            }
        }
    }
    if ($cleanupFailures.Count -ne 0) {
        Write-Warning "Open-Shell theme files were published, but transaction cleanup was incomplete: $($cleanupFailures -join '; ')"
    }
}
