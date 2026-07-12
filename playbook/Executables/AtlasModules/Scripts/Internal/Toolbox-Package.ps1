# Shared latest-channel Toolbox acquisition and installation.

function Test-AtlasToolboxInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$ExpectedVersion,

        [string]$ProgramFilesRoot = [Environment]::GetFolderPath(
            [Environment+SpecialFolder]::ProgramFiles
        )
    )

    $installDirectory = [IO.Path]::Combine($ProgramFilesRoot, 'Atlas Toolbox')
    $toolboxPath = [IO.Path]::Combine($installDirectory, 'AtlasToolbox.exe')
    if (-not [IO.Directory]::Exists($installDirectory) -or
        -not [IO.File]::Exists($toolboxPath)) {
        return $false
    }

    $directory = Get-Item -LiteralPath $installDirectory -Force -ErrorAction Stop
    $toolbox = Get-Item -LiteralPath $toolboxPath -Force -ErrorAction Stop
    if (($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($toolbox.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $toolbox.PSIsContainer -or $toolbox.Length -le 0) {
        throw 'The installed Toolbox path is not a normal non-empty file beneath a normal Program Files directory.'
    }

    try {
        $installedVersion = [string](Get-ItemPropertyValue `
            -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\AtlasOS\Toolbox' `
            -Name 'Version' `
            -ErrorAction Stop)
    }
    catch {
        return $false
    }

    return [string]::Equals(
        $installedVersion,
        $ExpectedVersion,
        [StringComparison]::Ordinal
    )
}

function Install-AtlasToolboxPackage {
    [CmdletBinding()]
    param()

    $downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
    if (-not [IO.File]::Exists($downloadIntegrity)) {
        throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
    }
    . $downloadIntegrity

    # Toolbox intentionally follows the repository's latest stable release so
    # a Toolbox update does not require a playbook release. Toolbox is currently
    # unsigned and unattested, so this product policy accepts control of the
    # reviewed immutable Atlas-OS organization/repository identities as its
    # publisher authority. GitHub's server-computed per-asset SHA-256 and byte
    # size provide a strict metadata-to-download binding, but are not an
    # independent publisher signature.
    $toolboxRelease = Get-AtlasLatestGitHubReleaseAsset `
        -Owner 'Atlas-OS' `
        -Repository 'atlas-toolbox' `
        -AssetName 'AtlasToolbox-Setup.exe' `
        -ExpectedRepositoryId 929016610 `
        -ExpectedOwnerId 78708182

    if (Test-AtlasToolboxInstallation -ExpectedVersion $toolboxRelease.Version) {
        Write-Output "AtlasOS Toolbox $($toolboxRelease.Version) is already installed."
        return
    }

    $tempDirectory = $null
    $cleanupStaging = $true
    try {
        $tempDirectory = New-AtlasProtectedStagingDirectory
        $toolboxPath = Join-Path -Path $tempDirectory -ChildPath 'toolbox.exe'
        Write-Output "Downloading Toolbox $($toolboxRelease.Version)..."
        Invoke-AtlasPinnedDownload `
            -Uri $toolboxRelease.Uri `
            -Destination $toolboxPath `
            -Sha256 $toolboxRelease.Sha256 `
            -ExpectedBytes $toolboxRelease.Size | Out-Null

        Write-Output 'Installing Toolbox...'
        $originalTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
        $originalTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')
        try {
            # Inno Setup's loader extracts and executes a second-stage binary
            # beneath inherited TEMP/TMP. Keep that stage inside the protected
            # directory that contains the verified outer installer.
            [Environment]::SetEnvironmentVariable('TEMP', $tempDirectory, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $tempDirectory, 'Process')
            $installerResult = Invoke-AtlasContainedProcess `
                -FilePath $toolboxPath `
                -ArgumentList ([string[]]@(
                    '/verysilent'
                    '/install'
                    '/MERGETASKS=desktopicon'
                )) `
                -WorkingDirectory $tempDirectory `
                -Description 'The Toolbox installer' `
                -Hidden `
                -NoWindow
            $installerExitCode = [uint32]$installerResult.ExitCodeUInt32
            if ($installerExitCode -ne 0) {
                throw "Installing Toolbox failed with exit code $installerExitCode."
            }
            if (-not (Test-AtlasToolboxInstallation -ExpectedVersion $toolboxRelease.Version)) {
                throw "The Toolbox installer exited successfully but Toolbox $($toolboxRelease.Version) did not satisfy its installed-file and version postconditions."
            }
        }
        finally {
            [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
        }
    }
    catch {
        if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
            $cleanupStaging = $false
            Write-Warning "Toolbox process-tree containment could not be confirmed; protected staging is retained at '$tempDirectory'."
        }
        throw
    }
    finally {
        if ($cleanupStaging -and $tempDirectory -and
            (Test-Path -LiteralPath $tempDirectory -PathType Container)) {
            Remove-Item -LiteralPath $tempDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
