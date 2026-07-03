Set-StrictMode -Version 3.0

$script:IsWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::Windows)

#region Private helpers

function New-TemporaryDirectory {
    $tempPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid().Guid)
    return New-Item -ItemType Directory -Path $tempPath -Force
}

function Set-ParentDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Path $Path -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

#endregion

function Resolve-SevenZip {
    <#
    .SYNOPSIS
        Locates a 7-Zip compatible executable (7z, 7zz or the installed 7-Zip copy on Windows).
    #>
    $candidates = @('7z', '7zz')

    foreach ($candidate in $candidates) {
        $commandInfo = Get-Command -Name $candidate -ErrorAction SilentlyContinue
        if ($commandInfo) {
            return $commandInfo.Source
        }
    }

    if ($script:IsWindowsPlatform) {
        $programFiles = [Environment]::GetFolderPath('ProgramFiles')
        if ($programFiles) {
            $installedPath = Join-Path -Path $programFiles -ChildPath '7-Zip\7z.exe'
            if (Test-Path -LiteralPath $installedPath) {
                return $installedPath
            }
        }
    }

    throw 'This script requires 7-Zip or NanaZip to be installed to continue.'
}

function Invoke-SevenZip {
    <#
    .SYNOPSIS
        Runs 7-Zip with the given arguments, recovering interrupted "<archive>.tmp" writes
        that 7-Zip leaves behind when updating password-protected zip archives.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$SevenZipPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [string]$ErrorContext = '7-Zip operation',
        [string]$ArchivePath
    )

    $previousErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $processOutput = & $SevenZipPath @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    $recovered = $false

    if ($ArchivePath) {
        $archiveDirectory = Split-Path -Path $ArchivePath -Parent
        $archiveLeaf = Split-Path -Path $ArchivePath -Leaf
        $primaryTempPath = "$ArchivePath.tmp"

        $candidateItems = @()
        if (Test-Path -LiteralPath $primaryTempPath) {
            $candidateItems += Get-Item -LiteralPath $primaryTempPath
        }

        if ($archiveDirectory) {
            $additionalCandidates = Get-ChildItem -LiteralPath $archiveDirectory -Filter "$archiveLeaf.tmp*" -ErrorAction SilentlyContinue
            foreach ($item in $additionalCandidates) {
                if ($primaryTempPath -and ($item.FullName -eq $primaryTempPath)) {
                    continue
                }
                $candidateItems += $item
            }
        }

        if ($candidateItems) {
            $candidateItems = $candidateItems | Sort-Object LastWriteTime -Descending
            $targetName = $archiveLeaf

            foreach ($candidate in $candidateItems) {
                for ($attempt = 0; $attempt -lt 5 -and -not $recovered; $attempt++) {
                    try {
                        Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue
                        Rename-Item -LiteralPath $candidate.FullName -NewName $targetName -Force
                        $recovered = $true
                        break
                    }
                    catch {
                        if ($attempt -eq 4) {
                            $warningMessage = "Failed to recover archive from temporary file '{0}': {1}" -f $candidate.FullName, $_.Exception.Message
                            Write-Warning $warningMessage
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }

                if ($recovered) {
                    break
                }
            }

            if (Test-Path -LiteralPath $ArchivePath) {
                foreach ($candidate in $candidateItems) {
                    if (Test-Path -LiteralPath $candidate.FullName) {
                        Remove-Item -LiteralPath $candidate.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }

    if ($exitCode -ne 0 -and $recovered) {
        $exitCode = 0
    }

    if ($exitCode -ne 0) {
        $message = "$ErrorContext failed with exit code $exitCode while executing '$SevenZipPath'."
        if ($processOutput) {
            $message += " Output:`n$($processOutput -join [Environment]::NewLine)"
        }
        throw $message
    }

    return $processOutput
}

function Get-PlaybookVersion {
    <#
    .SYNOPSIS
        Parses playbook.conf and returns version metadata.
    .OUTPUTS
        PSCustomObject with Version, Title, IsDev and VersionLabel (e.g. "v0.5.1 (dev)").
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PlaybookConfPath
    )

    if (-not (Test-Path -LiteralPath $PlaybookConfPath -PathType Leaf)) {
        throw "playbook.conf not found at '$PlaybookConfPath'."
    }

    $confXml = [xml](Get-Content -Path $PlaybookConfPath -Raw -Encoding UTF8)
    $playbookNode = $confXml.Playbook

    if (-not $playbookNode) {
        throw "'$PlaybookConfPath' does not contain a <Playbook> root element."
    }

    if ($playbookNode.Version -notmatch '^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$') {
        throw "Invalid version format '$($playbookNode.Version)' in '$PlaybookConfPath'."
    }

    $isDev = $playbookNode.Title -match '\(dev\)'
    $versionLabel = "v$($playbookNode.Version)"
    if ($isDev) {
        $versionLabel += ' (dev)'
    }

    return [pscustomobject]@{
        Version      = $playbookNode.Version
        Title        = $playbookNode.Title
        IsDev        = $isDev
        VersionLabel = $versionLabel
    }
}

function Get-AvailableArchiveName {
    <#
    .SYNOPSIS
        Picks a non-conflicting archive file name, optionally replacing an existing one.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$BaseName,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [switch]$AllowReplace
    )

    $candidate = $BaseName
    $candidatePath = Join-Path -Path $WorkingDirectory -ChildPath $candidate

    if ($AllowReplace -and (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        try {
            $stream = [IO.File]::Open($candidatePath, 'Open', 'Read', 'Write')
            $stream.Close()
            Remove-Item -LiteralPath $candidatePath -Force
        }
        catch {
            Write-Warning "Couldn't replace '$candidate', it's in use."
            $AllowReplace = $false
        }
    }

    $counter = 1
    while ((-not $AllowReplace) -and (Test-Path -LiteralPath (Join-Path -Path $WorkingDirectory -ChildPath $candidate) -PathType Leaf)) {
        $candidate = "{0} ({1}).apbx" -f $DisplayName, $counter
        $counter++
    }

    return $candidate
}

function New-StagedPlaybookConf {
    <#
    .SYNOPSIS
        Writes a copy of playbook.conf with the requested requirement lines stripped.
        Used for dev builds so they install on unsupported/unverified machines.
    .OUTPUTS
        $true when a staged copy was written to DestinationPath.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PlaybookConfPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath,
        [switch]$RemoveRequirements,
        [switch]$RemoveWinverRequirement,
        [switch]$RemoveVerification
    )

    $patternTokens = @()
    if ($RemoveRequirements) { $patternTokens += '<Requirement>' }
    if ($RemoveWinverRequirement) { $patternTokens += '<string>', '</SupportedBuilds>', '<SupportedBuilds>' }
    if ($RemoveVerification) { $patternTokens += '<ProductCode>' }

    if ($patternTokens.Count -eq 0) {
        return $false
    }

    Set-ParentDirectory -Path $DestinationPath
    $pattern = [string]::Join('|', $patternTokens)
    Get-Content -Path $PlaybookConfPath -Encoding UTF8 |
        Where-Object { $_ -notmatch $pattern } |
        Set-Content -Path $DestinationPath -Encoding UTF8

    return (Test-Path -LiteralPath $DestinationPath)
}

function Add-LiveLogAction {
    <#
    .SYNOPSIS
        Writes a copy of custom.yml with a live-log console action injected as the first
        action, tailing AME Wizard's OutputBuffer.txt during installation.
    .OUTPUTS
        $true when a staged copy was written to DestinationPath.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$CustomYmlPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $CustomYmlPath -PathType Leaf)) {
        Write-Warning "Can't find '$CustomYmlPath', not adding live log."
        return $false
    }

    Set-ParentDirectory -Path $DestinationPath
    Copy-Item -Path $CustomYmlPath -Destination $DestinationPath -Force

    $customYml = Get-Content -Path $DestinationPath
    $actionsIndex = $customYml.IndexOf('actions:')
    if ($actionsIndex -lt 0) {
        Write-Warning "Can't find 'actions:' in '$CustomYmlPath', not adding live log."
        Remove-Item -LiteralPath $DestinationPath -Force -ErrorAction SilentlyContinue
        return $false
    }

    $liveLogScript = {
        $a = Join-Path (Get-ChildItem (Join-Path $([Environment]::GetFolderPath('CommonApplicationData')) '\AME\Logs') -Directory |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1).FullName '\OutputBuffer.txt';
        while ($true) { Get-Content -Wait -LiteralPath $a -EA 0 | Write-Output; Start-Sleep 1 }
    }
    $liveLogText = [string]$liveLogScript
    $liveLogText = $liveLogText -replace '"', '"""'
    $liveLogText = $liveLogText -replace "'", "''"
    $liveLogText = $liveLogText.Trim() -replace "`r?`n", ' '

    $liveLogAction = "  - !cmd: {command: 'start `"AME Wizard Live Log`" PowerShell -NoP -C `"$liveLogText`"'}"

    $preActions = $customYml[0..$actionsIndex]
    $postActions = @()
    if ($actionsIndex + 1 -lt $customYml.Count) {
        $postActions = $customYml[($actionsIndex + 1)..($customYml.Count - 1)]
    }

    @($preActions) + @($liveLogAction) + @($postActions) | Set-Content -Path $DestinationPath -Encoding UTF8
    return $true
}

function Remove-DependencyBlock {
    <#
    .SYNOPSIS
        Writes a copy of start.yml with the "NO LOCAL BUILD" block removed, so local test
        builds skip steps that only work in a production install (DISM sources, downloads).
    .OUTPUTS
        $true when a staged copy was written to DestinationPath.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$StartYmlPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $StartYmlPath -PathType Leaf)) {
        Write-Warning "Can't find '$StartYmlPath', not removing dependencies section."
        return $false
    }

    $startYmlContent = Get-Content -Path $StartYmlPath -Raw -Encoding UTF8
    $blockPattern = '  ################ NO LOCAL BUILD ################.*?  ################ END NO LOCAL BUILD ################\r?\n?'
    $updatedStartYml = [regex]::Replace($startYmlContent, $blockPattern, '', 'Singleline')

    if ($updatedStartYml -eq $startYmlContent) {
        Write-Warning "Couldn't find NO LOCAL BUILD block in '$StartYmlPath', not removing dependencies section."
        return $false
    }

    Set-ParentDirectory -Path $DestinationPath
    Set-Content -Path $DestinationPath -Value $updatedStartYml -Encoding UTF8
    return $true
}

function Set-OemVersionStamp {
    <#
    .SYNOPSIS
        Writes a copy of the OEM information script with the AtlasVersionUndefined
        placeholder replaced by the playbook version label.
    .OUTPUTS
        $true when a staged copy was written to DestinationPath.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$VersionLabel,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        Write-Warning "Can't find '$ScriptPath', not setting OEM version."
        return $false
    }

    $oemContent = Get-Content -Path $ScriptPath -Raw -Encoding UTF8
    $updatedOemContent = $oemContent -replace 'AtlasVersionUndefined', $VersionLabel

    if ($updatedOemContent -eq $oemContent) {
        Write-Warning "Couldn't find OEM string 'AtlasVersionUndefined', not updating OEM version."
        return $false
    }

    Set-ParentDirectory -Path $DestinationPath
    Set-Content -Path $DestinationPath -Value $updatedOemContent -Encoding UTF8
    return $true
}

function New-Apbx {
    <#
    .SYNOPSIS
        Packages the playbook directory into a renamed, optionally password-protected ZIP
        (.apbx) understood by AME Wizard, applying dev-build staging overrides on top.
    .OUTPUTS
        Full path of the built .apbx file.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PlaybookPath,
        [string]$OutputDirectory,
        [string]$FileName = 'Atlas Test',
        [switch]$AddLiveLog,
        [switch]$RemoveDependencies,
        [switch]$RemoveRequirements,
        [switch]$RemoveWinverRequirement,
        [switch]$RemoveVerification,
        [switch]$NoPassword,
        [switch]$ReplaceOldPlaybook
    )

    $PlaybookPath = (Resolve-Path -LiteralPath $PlaybookPath).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path -Path $PlaybookPath -ChildPath 'playbook.conf') -PathType Leaf)) {
        throw "playbook.conf not found in '$PlaybookPath' - not a playbook directory."
    }

    if (-not $OutputDirectory) {
        $OutputDirectory = $PlaybookPath
    }
    $OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).ProviderPath

    $sevenZipPath = Resolve-SevenZip

    $apbxFileName = Get-AvailableArchiveName -BaseName "$FileName.apbx" -WorkingDirectory $OutputDirectory -DisplayName $FileName -AllowReplace:$ReplaceOldPlaybook
    $apbxPath = Join-Path -Path $OutputDirectory -ChildPath $apbxFileName

    $rootTempDir = $null
    $filesListPath = $null
    $previousLocation = Get-Location

    try {
        Set-Location -LiteralPath $PlaybookPath

        # Staged overrides are written into a temp mirror of the playbook tree and added
        # to the archive after the main pass, replacing the originals.
        $rootTempDir = New-TemporaryDirectory
        $stagingPath = Join-Path -Path $rootTempDir.FullName -ChildPath 'playbook'
        New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

        $stagedPlaybookConf = New-StagedPlaybookConf `
            -PlaybookConfPath (Join-Path -Path $PlaybookPath -ChildPath 'playbook.conf') `
            -DestinationPath (Join-Path -Path $stagingPath -ChildPath 'playbook.conf') `
            -RemoveRequirements:$RemoveRequirements `
            -RemoveWinverRequirement:$RemoveWinverRequirement `
            -RemoveVerification:$RemoveVerification

        $customYmlRelativePath = Join-Path -Path 'Configuration' -ChildPath 'custom.yml'
        $stagedCustomYml = $false
        if ($AddLiveLog) {
            $stagedCustomYml = Add-LiveLogAction `
                -CustomYmlPath (Join-Path -Path $PlaybookPath -ChildPath $customYmlRelativePath) `
                -DestinationPath (Join-Path -Path $stagingPath -ChildPath $customYmlRelativePath)
        }

        $startYmlRelativePath = Join-Path -Path (Join-Path -Path 'Configuration' -ChildPath 'atlas') -ChildPath 'start.yml'
        $stagedStartYml = $false
        if ($RemoveDependencies) {
            $stagedStartYml = Remove-DependencyBlock `
                -StartYmlPath (Join-Path -Path $PlaybookPath -ChildPath $startYmlRelativePath) `
                -DestinationPath (Join-Path -Path $stagingPath -ChildPath $startYmlRelativePath)
        }

        $oemScriptRelativePath = 'Executables\AtlasModules\Scripts\Tasks\Set-OemInformation.ps1'
        $stagedOemScript = $false
        try {
            $versionInfo = Get-PlaybookVersion -PlaybookConfPath (Join-Path -Path $PlaybookPath -ChildPath 'playbook.conf')
            $stagedOemScript = Set-OemVersionStamp `
                -ScriptPath (Join-Path -Path $PlaybookPath -ChildPath $oemScriptRelativePath) `
                -VersionLabel $versionInfo.VersionLabel `
                -DestinationPath (Join-Path -Path $stagingPath -ChildPath $oemScriptRelativePath)
        }
        catch {
            Write-Warning "Failed to process OEM information: $($_.Exception.Message)"
        }

        # Files replaced by staged overrides are excluded from the main pass so the
        # archive never contains duplicates.
        $excludeFiles = @('*.apbx', '*.apbx.tmp')
        if ($stagedCustomYml) { $excludeFiles += 'custom.yml' }
        if ($stagedStartYml) { $excludeFiles += 'start.yml' }
        if ($stagedPlaybookConf) { $excludeFiles += 'playbook.conf' }
        if ($stagedOemScript) { $excludeFiles += 'Set-OemInformation.ps1' }

        $filesListPath = [IO.Path]::GetTempFileName()
        $rootPathNormalized = $PlaybookPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $rootPrefix = $rootPathNormalized + [IO.Path]::DirectorySeparatorChar

        $filesToInclude = Get-ChildItem -File -Exclude $excludeFiles -Recurse
        $relativePaths = foreach ($file in $filesToInclude) {
            $fullName = $file.FullName
            if ($fullName.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                $relative = $fullName.Substring($rootPrefix.Length)
            }
            elseif ($fullName.StartsWith($rootPathNormalized, [StringComparison]::OrdinalIgnoreCase)) {
                $relative = $fullName.Substring($rootPathNormalized.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
            }
            else {
                $relative = $file.Name
            }

            $relative -replace '\\', '/'
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($filesListPath, $relativePaths, $utf8NoBom)

        $passwordArgs = @()
        if (-not $NoPassword) {
            $passwordArgs += '-pmalte'
        }

        # Store-level compression for speed; -bs* flags keep 7-Zip quiet.
        $archiveArgs = @('a', '-tzip', '-y', '-mx1', '-bso0', '-bse0', '-bsp0')
        if ($script:IsWindowsPlatform) {
            $archiveArgs += '-spf'
        }
        $archiveArgs += $passwordArgs
        $archiveArgs += $apbxPath
        # The @listfile syntax must not be quoted or 7-Zip misparses it.
        $archiveArgs += "@$filesListPath"

        Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $archiveArgs -ErrorContext 'Creating APBX archive' -ArchivePath $apbxPath | Out-Null

        $stagedFiles = Get-ChildItem -Path $stagingPath -File -Recurse -ErrorAction SilentlyContinue
        if ($stagedFiles) {
            Set-Location -LiteralPath $stagingPath
            try {
                $updateArgs = @('u', '-bso0', '-bse0', '-bsp0')
                $updateArgs += $passwordArgs
                $updateArgs += $apbxPath
                $updateArgs += '*'

                Invoke-SevenZip -SevenZipPath $sevenZipPath -ArgumentList $updateArgs -ErrorContext 'Adding staged overrides' -ArchivePath $apbxPath | Out-Null
            }
            finally {
                Set-Location -LiteralPath $PlaybookPath
            }
        }

        $apbxTmpPath = "$apbxPath.tmp"
        if (Test-Path -LiteralPath $apbxTmpPath) {
            Remove-Item -LiteralPath $apbxPath -Force -ErrorAction SilentlyContinue
            Rename-Item -LiteralPath $apbxTmpPath -NewName (Split-Path -Path $apbxPath -Leaf)
        }

        return $apbxPath
    }
    finally {
        Set-Location -LiteralPath $previousLocation.ProviderPath

        if ($filesListPath -and (Test-Path -LiteralPath $filesListPath)) {
            Remove-Item -LiteralPath $filesListPath -Force -ErrorAction SilentlyContinue
        }

        if ($rootTempDir -and (Test-Path -LiteralPath $rootTempDir.FullName)) {
            Remove-Item -LiteralPath $rootTempDir.FullName -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}
