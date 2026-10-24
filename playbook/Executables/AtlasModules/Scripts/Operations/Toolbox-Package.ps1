# Shared Toolbox acquisition and installation: the latest release on GitHub, or the
# installer a release candidate carries.

function Get-AtlasBundledToolbox {
    <#
    .SYNOPSIS
        The Toolbox installer bundled with this Atlas package, or $null when there is
        none. Release candidates carry the Toolbox they were tested with, because the
        release they need may not be published yet; releases install the latest one
        from GitHub. The files sit in AtlasModules, which only administrators can change.
    #>
    [CmdletBinding()]
    param(
        [string]$Root = [IO.Path]::Combine(
            (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)), 'Bundled', 'Toolbox')
    )

    $manifestPath = [IO.Path]::Combine($Root, 'AtlasToolbox-Setup.json')
    if (-not [IO.File]::Exists($manifestPath)) {
        return $null
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $version = [string]$manifest.version
    $sha256 = [string]$manifest.sha256
    $size = $manifest.size -as [long]
    if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$' -or $sha256 -notmatch '^[0-9A-Fa-f]{64}$' -or
        $null -eq $size -or $size -le 0) {
        throw "The bundled Toolbox manifest at '$manifestPath' needs a version, a SHA-256 and a size."
    }
    $installerPath = [IO.Path]::Combine($Root, 'AtlasToolbox-Setup.exe')
    if (-not [IO.File]::Exists($installerPath)) {
        throw "The bundled Toolbox installer is missing at '$installerPath'."
    }
    [pscustomobject]@{
        Version = $version
        Sha256  = $sha256.ToUpperInvariant()
        Size    = $size
        Path    = $installerPath
    }
}

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

    $downloadModule = Join-Path (Split-Path -Parent $PSScriptRoot) 'Modules\Atlas.Download\Atlas.Download.psd1'
    if (-not [IO.File]::Exists($downloadModule)) {
        throw "The Atlas.Download module manifest is missing at '$downloadModule'."
    }
    Import-Module -Name $downloadModule -ErrorAction Stop

    # Toolbox tracks its latest stable release so its updates don't need an Atlas
    # release. It is unsigned: trust rests on the pinned Atlas-OS owner and repository
    # IDs, and GitHub's per-asset SHA-256 and size tie the download to that release.
    # A bundled installer is held to its manifest's SHA-256 and size the same way.
    $bundledToolbox = Get-AtlasBundledToolbox
    $bundled = $null -ne $bundledToolbox
    $toolboxRelease = if ($bundled) {
        $bundledToolbox
    }
    else {
        Get-AtlasLatestGitHubReleaseAsset `
            -Owner 'Atlas-OS' `
            -Repository 'atlas-toolbox' `
            -AssetName 'AtlasToolbox-Setup.exe' `
            -ExpectedRepositoryId 929016610 `
            -ExpectedOwnerId 78708182
    }

    if (Test-AtlasToolboxInstallation -ExpectedVersion $toolboxRelease.Version) {
        Write-AtlasNote -Text "AtlasOS Toolbox $($toolboxRelease.Version) is already installed."
        return
    }

    $tempDirectory = $null
    $cleanupStaging = $true
    try {
        $tempDirectory = New-AtlasProtectedStagingDirectory
        $toolboxPath = Join-Path -Path $tempDirectory -ChildPath 'toolbox.exe'
        if ($bundled) {
            # The copy that runs is the one checked, so nothing can change it in between.
            [IO.File]::Copy($toolboxRelease.Path, $toolboxPath)
            $copied = Get-Item -LiteralPath $toolboxPath -Force -ErrorAction Stop
            $copiedHash = (Get-FileHash -LiteralPath $toolboxPath -Algorithm SHA256 -ErrorAction Stop).Hash
            if ($copied.Length -ne $toolboxRelease.Size -or $copiedHash -cne $toolboxRelease.Sha256) {
                throw "The bundled Toolbox installer doesn't match its manifest (SHA-256 $copiedHash, $($copied.Length) bytes)."
            }
        }
        else {
            Write-AtlasStep -Text "Downloading AtlasOS Toolbox $($toolboxRelease.Version)..."
            Invoke-AtlasPinnedDownload `
                -Uri $toolboxRelease.Uri `
                -Destination $toolboxPath `
                -Sha256 $toolboxRelease.Sha256 `
                -ExpectedBytes $toolboxRelease.Size | Out-Null
        }

        Write-AtlasStep -Text "Installing AtlasOS Toolbox $($toolboxRelease.Version)..."
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
                throw "The Toolbox installer exited successfully, but Toolbox $($toolboxRelease.Version) is not installed as expected."
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
