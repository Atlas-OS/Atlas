# Atlas.Core domain: active install state and post-install flag context.
#
# While installation is active, mode, identity, and FeaturePage options come from
# Atlas.InstallState. After successful completion archives that state, the published
# Upgrade, Interactive, and option flags remain the compatibility contract.

$script:AtlasContext = $null

function Read-AtlasActiveInstallState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )

    $statePath = Join-Path -Path $WindowsPath -ChildPath 'AtlasOS\Install\active.json'
    if (-not (Test-Path -LiteralPath $statePath -ErrorAction Stop)) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf -ErrorAction Stop)) {
        throw "The Atlas install-state path is not a regular file: '$statePath'."
    }

    $stateManifest = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot `
        -ChildPath '..\..\Atlas.InstallState\Atlas.InstallState.psd1'))
    if (-not (Test-Path -LiteralPath $stateManifest -PathType Leaf)) {
        throw "The active Atlas install state exists, but its reader module is missing: '$stateManifest'."
    }

    Import-Module -Name $stateManifest -DisableNameChecking -ErrorAction Stop
    return Get-AtlasInstallState -StatePath $statePath
}

function Get-AtlasContext {
    <#
    .SYNOPSIS
        Returns cached information about the machine and the current install run.
    .OUTPUTS
        PSCustomObject with filesystem paths, Windows facts and the authoritative install
        mode, option set, target version and interactive-user identity.
    #>
    param(
        [switch]$Refresh,

        # Read-only seams keep context behavior deterministic in Pester without touching
        # the host registry or canonical Windows transaction store.
        [string]$WindowsPath,
        [scriptblock]$StateReader,
        [scriptblock]$WindowsBuildReader,
        [scriptblock]$OobeReader
    )

    $usingReadSeam = $PSBoundParameters.ContainsKey('WindowsPath') -or
        $PSBoundParameters.ContainsKey('StateReader') -or
        $PSBoundParameters.ContainsKey('WindowsBuildReader') -or
        $PSBoundParameters.ContainsKey('OobeReader')
    if ($script:AtlasContext -and -not $Refresh -and -not $usingReadSeam) {
        return $script:AtlasContext
    }

    $winDir = if ([string]::IsNullOrWhiteSpace($WindowsPath)) {
        [Environment]::GetFolderPath('Windows')
    }
    else {
        [IO.Path]::GetFullPath($WindowsPath)
    }
    $atlasModulesPath = Join-Path -Path $winDir -ChildPath 'AtlasModules'
    $flagsPath = Join-Path -Path $atlasModulesPath -ChildPath 'Flags'

    $windowsBuild = 0
    try {
        $buildNumber = if ($null -ne $WindowsBuildReader) {
            & $WindowsBuildReader
        }
        else {
            (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
                -Name CurrentBuildNumber -ErrorAction Stop).CurrentBuildNumber
        }
        $windowsBuild = [int]$buildNumber
    }
    catch {
        Write-Warning "Couldn't read the Windows build number: $($_.Exception.Message)"
    }

    $statePath = Join-Path -Path $winDir -ChildPath 'AtlasOS\Install\active.json'
    $installState = if ($null -ne $StateReader) {
        & $StateReader $statePath
    }
    else {
        Read-AtlasActiveInstallState -WindowsPath $winDir
    }

    $isInstallStateBacked = $null -ne $installState
    $mode = $null
    $targetVersion = $null
    $interactiveUserSid = $null
    $interactiveUserSessionId = $null
    $transactionId = $null
    $options = @()
    if ($isInstallStateBacked) {
        $mode = [string]$installState.mode
        if ($mode -cnotin @('Fresh', 'Upgrade', 'Reapply')) {
            throw "The Atlas install-state mode '$mode' is invalid."
        }
        $targetVersion = [string]$installState.targetVersion
        $interactiveUserSid = if ([string]::IsNullOrWhiteSpace([string]$installState.userSid)) {
            $null
        }
        else {
            [string]$installState.userSid
        }
        if ($null -ne $installState.userSessionId) {
            $interactiveUserSessionId = [long]$installState.userSessionId
        }
        $transactionId = [string]$installState.transactionId
        $options = @($installState.options | ForEach-Object { [string]$_ })
    }

    $isUpgrade = if ($isInstallStateBacked) {
        $mode -cin @('Upgrade', 'Reapply')
    }
    else {
        Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath 'Upgrade.flag') -PathType Leaf
    }

    $isOobe = if ($isInstallStateBacked) {
        [bool]$installState.isOobe
    }
    else {
        # Completion publishes Interactive.flag for normal installs. Its absence can
        # mean OOBE or a machine predating that contract, so consult the live setup
        # indicator only when context is flag-backed.
        $flagBackedOobe = $false
        if (-not (Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath 'Interactive.flag') -PathType Leaf)) {
            try {
                $oobeInProgress = if ($null -ne $OobeReader) {
                    & $OobeReader
                }
                else {
                    (Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup' -Name 'OOBEInProgress' `
                        -ErrorAction Stop).OOBEInProgress
                }
                $flagBackedOobe = ($oobeInProgress -eq 1)
            }
            catch {
                $flagBackedOobe = $false
            }
        }
        $flagBackedOobe
    }

    $script:AtlasContext = [pscustomobject]@{
        WinDir             = $winDir
        AtlasModulesPath   = $atlasModulesPath
        FlagsPath          = $flagsPath
        LogsPath           = Join-Path -Path $atlasModulesPath -ChildPath 'Logs'
        IsArm64            = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
        WindowsBuild       = $windowsBuild
        IsUpgrade          = $isUpgrade
        IsOobe             = $isOobe
        IsInstallStateBacked     = $isInstallStateBacked
        Mode                     = if ($isInstallStateBacked) { $mode } else { 'Legacy' }
        TargetVersion            = $targetVersion
        InteractiveUserSid       = $interactiveUserSid
        InteractiveUserSessionId = $interactiveUserSessionId
        TransactionId            = $transactionId
        Options                  = $options
    }

    return $script:AtlasContext
}

function Test-AtlasOption {
    <#
    .SYNOPSIS
        Returns whether the active install state contains an AME Wizard FeaturePage
        option. After completion, reads the corresponding published option flag.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $context = Get-AtlasContext
    if ($context.IsInstallStateBacked) {
        return @($context.Options) -ccontains $Name
    }

    $flagsPath = $context.FlagsPath
    return Test-Path -LiteralPath (Join-Path -Path $flagsPath -ChildPath "option-$Name.flag") -PathType Leaf
}
