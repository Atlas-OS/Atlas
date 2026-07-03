# Atlas.Core domain: install context and option flags.
#
# AME Wizard evaluates FeaturePage options, onUpgrade and oobe gating in YAML only.
# The shim (Configuration/custom.yml) translates those decisions into flag files under
# %windir%\AtlasModules\Flags right after the payload copy, and this module is how the
# rest of the framework reads them.

$script:AtlasContext = $null

function Get-AtlasContext {
    <#
    .SYNOPSIS
        Returns cached information about the machine and the current install run.
    .OUTPUTS
        PSCustomObject with WinDir, AtlasModulesPath, FlagsPath, LogsPath, IsArm64,
        WindowsBuild, IsUpgrade and IsOobe.
    #>
    param(
        [switch]$Refresh
    )

    if ($script:AtlasContext -and -not $Refresh) {
        return $script:AtlasContext
    }

    $winDir = [Environment]::GetFolderPath('Windows')
    $atlasModulesPath = Join-Path -Path $winDir -ChildPath 'AtlasModules'
    $flagsPath = Join-Path -Path $atlasModulesPath -ChildPath 'Flags'

    $windowsBuild = 0
    try {
        $buildNumber = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuildNumber -ErrorAction Stop).CurrentBuildNumber
        $windowsBuild = [int]$buildNumber
    }
    catch {
        Write-Warning "Couldn't read the Windows build number: $($_.Exception.Message)"
    }

    # The shim writes Interactive.flag for normal (non-OOBE) installs. When it is absent,
    # fall back to the live OOBE indicator so post-install tools also resolve correctly.
    $isOobe = $false
    if (-not (Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath 'Interactive.flag') -PathType Leaf)) {
        try {
            $oobeInProgress = (Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'OOBEInProgress' -ErrorAction Stop).OOBEInProgress
            $isOobe = ($oobeInProgress -eq 1)
        }
        catch {
            $isOobe = $false
        }
    }

    $script:AtlasContext = [pscustomobject]@{
        WinDir           = $winDir
        AtlasModulesPath = $atlasModulesPath
        FlagsPath        = $flagsPath
        LogsPath         = Join-Path -Path $atlasModulesPath -ChildPath 'Logs'
        IsArm64          = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
        WindowsBuild     = $windowsBuild
        IsUpgrade        = (Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath 'Upgrade.flag') -PathType Leaf)
        IsOobe           = $isOobe
    }

    return $script:AtlasContext
}

function Test-AtlasOption {
    <#
    .SYNOPSIS
        Returns whether the user selected the given AME Wizard FeaturePage option
        (e.g. 'defender-disable', 'browser-brave') during installation.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $flagsPath = (Get-AtlasContext).FlagsPath
    return Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath "option-$Name.flag") -PathType Leaf
}

function New-AtlasFlag {
    <#
    .SYNOPSIS
        Creates a named flag file under the Atlas flags directory.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $flagsPath = (Get-AtlasContext).FlagsPath
    if (-not (Test-Path -LiteralPath $flagsPath -PathType Container)) {
        New-Item -Path $flagsPath -ItemType Directory -Force | Out-Null
    }

    New-Item -Path (Join-Path -Path $flagsPath -ChildPath "$Name.flag") -ItemType File -Force | Out-Null
}

function Test-AtlasFlag {
    <#
    .SYNOPSIS
        Returns whether a named flag file exists under the Atlas flags directory.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $flagsPath = (Get-AtlasContext).FlagsPath
    return Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath "$Name.flag") -PathType Leaf
}
