# Transactional publication for the pinned Open-Shell theme payload.

function Get-AtlasOpenShellThemeFileSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [IO.File]::Open(
        $Path,
        [IO.FileMode]::Open,
        [IO.FileAccess]::Read,
        [IO.FileShare]::Read
    )
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
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
    $directory = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Description directory '$Path' is a reparse point."
    }

    $allowedWriters = @(
        'S-1-5-18',       # LocalSystem
        'S-1-5-32-544',   # Built-in Administrators
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464' # TrustedInstaller
    )
    $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
    try {
        $ownerSid = ([Security.Principal.NTAccount]$acl.Owner).Translate(
            [Security.Principal.SecurityIdentifier]
        ).Value
    }
    catch {
        $ownerSid = ([Security.Principal.SecurityIdentifier]$acl.Owner).Value
    }
    if ($ownerSid -notin $allowedWriters) {
        throw "$Description directory '$Path' has untrusted owner '$ownerSid'."
    }

    $writeMask = [Security.AccessControl.FileSystemRights]::WriteData -bor
        [Security.AccessControl.FileSystemRights]::AppendData -bor
        [Security.AccessControl.FileSystemRights]::WriteExtendedAttributes -bor
        [Security.AccessControl.FileSystemRights]::WriteAttributes -bor
        [Security.AccessControl.FileSystemRights]::Delete -bor
        [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles -bor
        [Security.AccessControl.FileSystemRights]::ChangePermissions -bor
        [Security.AccessControl.FileSystemRights]::TakeOwnership
    foreach ($rule in $acl.Access) {
        if ($rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or
            ($rule.FileSystemRights -band $writeMask) -eq 0) {
            continue
        }
        try {
            $writerSid = $rule.IdentityReference.Translate(
                [Security.Principal.SecurityIdentifier]
            ).Value
        }
        catch {
            throw "$Description directory '$Path' has an unresolvable writable principal '$($rule.IdentityReference)'."
        }
        if ($writerSid -notin $allowedWriters) {
            throw "$Description directory '$Path' grants write-like access to untrusted principal '$writerSid'."
        }
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
    $file = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($file.PSIsContainer -or
        ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $file.Length -ne $ExpectedBytes) {
        throw "The Open-Shell theme file '$Path' failed its normal-file or length check."
    }
    $actualHash = Get-AtlasOpenShellThemeFileSha256 -Path $Path
    if (-not $actualHash.Equals($ExpectedSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The Open-Shell theme file '$Path' failed its SHA-256 check."
    }
}

function Get-AtlasOpenShellThemeBytesSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Bytes)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $sha.Dispose()
    }
}

function Assert-AtlasOpenShellThemeMutableFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Description,
        [ValidateRange(1, 16777216)][long]$MaximumBytes = 16777216
    )

    if (-not [IO.File]::Exists($Path)) {
        throw "$Description is missing at '$Path'."
    }
    $file = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($file.PSIsContainer -or
        ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $file.Length -gt $MaximumBytes) {
        throw "$Description '$Path' is not a bounded normal file."
    }
    $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
    if (-not (Test-AtlasProtectedExecutionAcl -Acl $acl)) {
        throw "$Description '$Path' has an untrusted owner or writable principal."
    }
    return $file
}

function Write-AtlasOpenShellThemeBytesDurable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Bytes
    )

    if ([IO.File]::Exists($Path) -or [IO.Directory]::Exists($Path)) {
        throw "The Open-Shell theme transaction artifact '$Path' already exists."
    }
    $stream = [IO.File]::Open(
        $Path,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None
    )
    try {
        $stream.Write($Bytes, 0, $Bytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }
    $null = Assert-AtlasOpenShellThemeMutableFile `
        -Path $Path -Description 'Open-Shell theme transaction artifact'
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
    if ($file.PSIsContainer -or
        ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The Open-Shell theme target '$Path' is not a normal file."
    }
    if (-not (Test-AtlasProtectedExecutionAcl -Acl (
                Get-Acl -LiteralPath $Path -ErrorAction Stop
            ))) {
        throw "The Open-Shell theme target '$Path' has an untrusted owner or writable principal."
    }
    if ($file.Length -ne $ExpectedBytes) { return $false }
    return (Get-AtlasOpenShellThemeFileSha256 -Path $Path).Equals(
        $ExpectedSha256,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Repair-AtlasOpenShellThemeArtifacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$CandidatePath,
        [Parameter(Mandatory = $true)][string]$RollbackPath,
        [Parameter(Mandatory = $true)][long]$ExpectedBytes,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    if ([IO.Directory]::Exists($CandidatePath) -or [IO.Directory]::Exists($RollbackPath)) {
        throw "An Open-Shell theme transaction artifact is unexpectedly a directory for '$TargetPath'."
    }

    if ([IO.File]::Exists($RollbackPath)) {
        $rollback = Assert-AtlasOpenShellThemeMutableFile `
            -Path $RollbackPath -Description 'Open-Shell theme rollback artifact'
        if ([IO.File]::Exists($TargetPath)) {
            $target = Assert-AtlasOpenShellThemeMutableFile `
                -Path $TargetPath -Description 'Open-Shell theme target'
            $targetIsExpected = Test-AtlasOpenShellThemeExpectedFile `
                -Path $TargetPath `
                -ExpectedBytes $ExpectedBytes `
                -ExpectedSha256 $ExpectedSha256
            $targetMatchesRollback = $target.Length -eq $rollback.Length -and
                (Get-AtlasOpenShellThemeFileSha256 -Path $TargetPath).Equals(
                    (Get-AtlasOpenShellThemeFileSha256 -Path $RollbackPath),
                    [StringComparison]::OrdinalIgnoreCase
                )
            if (-not $targetIsExpected -and -not $targetMatchesRollback) {
                throw "The Open-Shell theme target and rollback artifact for '$TargetPath' are ambiguous."
            }
            [IO.File]::Delete($RollbackPath)
        }
        elseif ([IO.Directory]::Exists($TargetPath)) {
            throw "The Open-Shell theme rollback artifact cannot be recovered because '$TargetPath' is a directory."
        }
        else {
            [IO.File]::Move($RollbackPath, $TargetPath)
        }
    }

    if ([IO.File]::Exists($CandidatePath)) {
        Assert-AtlasOpenShellThemeFile `
            -Path $CandidatePath `
            -ExpectedBytes $ExpectedBytes `
            -ExpectedSha256 $ExpectedSha256
        $null = Assert-AtlasOpenShellThemeMutableFile `
            -Path $CandidatePath -Description 'Open-Shell theme candidate'
        if (Test-AtlasOpenShellThemeExpectedFile `
                -Path $TargetPath `
                -ExpectedBytes $ExpectedBytes `
                -ExpectedSha256 $ExpectedSha256) {
            [IO.File]::Delete($CandidatePath)
        }
    }
}

function Invoke-AtlasOpenShellThemeFileTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SourceDirectory,
        [Parameter(Mandatory = $true)][string]$SkinsDirectory,
        [Parameter(Mandatory = $true)][object[]]$ExpectedFiles
    )

    $sourceItems = @(Get-ChildItem -LiteralPath $SourceDirectory -Force -ErrorAction Stop)
    if ($sourceItems.Count -ne $ExpectedFiles.Count) {
        throw 'The extracted Open-Shell theme payload contains an unexpected number of entries.'
    }

    $seenNames = @{}
    foreach ($expected in $ExpectedFiles) {
        $name = [string]$expected.Name
        if ($name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' -or
            $seenNames.ContainsKey($name)) {
            throw "The Open-Shell theme manifest contains an invalid or duplicate file name '$name'."
        }
        $seenNames[$name] = $true
        $sourcePath = Join-Path -Path $SourceDirectory -ChildPath $name
        Assert-AtlasOpenShellThemeFile `
            -Path $sourcePath `
            -ExpectedBytes ([long]$expected.Length) `
            -ExpectedSha256 ([string]$expected.Sha256)
    }
    foreach ($sourceItem in $sourceItems) {
        if ($sourceItem.PSIsContainer -or -not $seenNames.ContainsKey($sourceItem.Name)) {
            throw "The extracted Open-Shell theme payload contains unexpected entry '$($sourceItem.Name)'."
        }
    }

    $records = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($expected in $ExpectedFiles) {
            $name = [string]$expected.Name
            $targetPath = Join-Path -Path $SkinsDirectory -ChildPath $name
            $candidatePath = "$targetPath.atlas-candidate"
            $rollbackPath = "$targetPath.atlas-rollback"

            Repair-AtlasOpenShellThemeArtifacts `
                -TargetPath $targetPath `
                -CandidatePath $candidatePath `
                -RollbackPath $rollbackPath `
                -ExpectedBytes ([long]$expected.Length) `
                -ExpectedSha256 ([string]$expected.Sha256)

            if (Test-AtlasOpenShellThemeExpectedFile `
                    -Path $targetPath `
                    -ExpectedBytes ([long]$expected.Length) `
                    -ExpectedSha256 ([string]$expected.Sha256)) {
                continue
            }

            $targetExisted = [IO.File]::Exists($targetPath)
            if ($targetExisted) {
                $target = Assert-AtlasOpenShellThemeMutableFile `
                    -Path $targetPath -Description 'Existing Open-Shell theme target'
                $priorBytes = [IO.File]::ReadAllBytes($target.FullName)
                $priorSha256 = Get-AtlasOpenShellThemeBytesSha256 -Bytes $priorBytes
            }
            elseif ([IO.Directory]::Exists($targetPath)) {
                throw "The Open-Shell theme target '$targetPath' is a directory."
            }
            else {
                $priorBytes = $null
                $priorSha256 = $null
            }

            $record = [pscustomobject]@{
                Name          = $name
                Target        = $targetPath
                Candidate     = $candidatePath
                Rollback      = $rollbackPath
                TargetExisted = $targetExisted
                PriorBytes    = $priorBytes
                PriorSha256   = $priorSha256
                Published     = $false
                Length        = [long]$expected.Length
                Sha256        = [string]$expected.Sha256
            }
            $records.Add($record)

            if (-not [IO.File]::Exists($candidatePath)) {
                $sourceBytes = [IO.File]::ReadAllBytes(
                    (Join-Path -Path $SourceDirectory -ChildPath $name)
                )
                Write-AtlasOpenShellThemeBytesDurable `
                    -Path $candidatePath -Bytes $sourceBytes
            }
            Assert-AtlasOpenShellThemeFile `
                -Path $candidatePath `
                -ExpectedBytes $record.Length `
                -ExpectedSha256 $record.Sha256

            if ($targetExisted) {
                [IO.File]::Replace($candidatePath, $targetPath, $rollbackPath)
            }
            else {
                [IO.File]::Move($candidatePath, $targetPath)
            }
            $record.Published = $true
            Assert-AtlasOpenShellThemeFile `
                -Path $targetPath `
                -ExpectedBytes $record.Length `
                -ExpectedSha256 $record.Sha256
            if ($targetExisted) {
                $rollbackBytes = [IO.File]::ReadAllBytes($rollbackPath)
                $rollbackSha256 = Get-AtlasOpenShellThemeBytesSha256 -Bytes $rollbackBytes
                if ($rollbackBytes.Length -ne $record.PriorBytes.Length -or
                    -not $rollbackSha256.Equals(
                        $record.PriorSha256,
                        [StringComparison]::OrdinalIgnoreCase
                    )) {
                    throw 'the atomic replacement backup does not match the prior target'
                }
                [IO.File]::Delete($rollbackPath)
                if ([IO.File]::Exists($rollbackPath)) {
                    throw 'the atomic replacement backup could not be retired'
                }
            }
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
                        if ([IO.Directory]::Exists($record.Rollback)) {
                            throw 'the deterministic rollback artifact is a directory'
                        }
                        if ([IO.File]::Exists($record.Rollback)) {
                            $existingRollback = [IO.File]::ReadAllBytes($record.Rollback)
                            $existingRollbackHash = Get-AtlasOpenShellThemeBytesSha256 `
                                -Bytes $existingRollback
                            if ($existingRollback.Length -ne $record.PriorBytes.Length -or
                                -not $existingRollbackHash.Equals(
                                    $record.PriorSha256,
                                    [StringComparison]::OrdinalIgnoreCase
                                )) {
                                throw 'the existing rollback artifact does not match the prior target'
                            }
                        }
                        else {
                            Write-AtlasOpenShellThemeBytesDurable `
                                -Path $record.Rollback -Bytes $record.PriorBytes
                        }
                        if ([IO.File]::Exists($record.Candidate) -or
                            [IO.Directory]::Exists($record.Candidate)) {
                            throw 'the deterministic displaced-target artifact is already occupied'
                        }
                        [IO.File]::Replace(
                            $record.Rollback,
                            $record.Target,
                            $record.Candidate
                        )
                        $restoredBytes = [IO.File]::ReadAllBytes($record.Target)
                        $restoredHash = Get-AtlasOpenShellThemeBytesSha256 -Bytes $restoredBytes
                        if ($restoredBytes.Length -ne $record.PriorBytes.Length -or
                            -not $restoredHash.Equals(
                                $record.PriorSha256,
                                [StringComparison]::OrdinalIgnoreCase
                            )) {
                            throw 'the prior target bytes were not restored exactly'
                        }
                        Assert-AtlasOpenShellThemeFile `
                            -Path $record.Candidate `
                            -ExpectedBytes $record.Length `
                            -ExpectedSha256 $record.Sha256
                        [IO.File]::Delete($record.Candidate)
                    }
                    else {
                        [IO.File]::Delete($record.Target)
                    }
                }
                elseif ($record.TargetExisted) {
                    $currentBytes = [IO.File]::ReadAllBytes($record.Target)
                    $currentHash = Get-AtlasOpenShellThemeBytesSha256 -Bytes $currentBytes
                    if ($currentBytes.Length -ne $record.PriorBytes.Length -or
                        -not $currentHash.Equals(
                            $record.PriorSha256,
                            [StringComparison]::OrdinalIgnoreCase
                        )) {
                        throw 'the target is neither the published payload nor the prior target'
                    }
                }
                elseif ([IO.File]::Exists($record.Target) -or
                    [IO.Directory]::Exists($record.Target)) {
                    throw 'a first-install target contains unknown data'
                }
                if ([IO.File]::Exists($record.Candidate)) {
                    Assert-AtlasOpenShellThemeFile `
                        -Path $record.Candidate `
                        -ExpectedBytes $record.Length `
                        -ExpectedSha256 $record.Sha256
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
}
