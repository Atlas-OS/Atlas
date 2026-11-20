# The Microsoft Defender install choice (defender-enable or defender-disable), applied
# through Atlas's NoDefender servicing package. Shared by the Components phase (Fresh and
# Rebase) and the Choices phase (Choose again). Runs as TrustedInstaller; the phase
# imports Atlas.Core, Atlas.Software and Atlas.Security.
#
# It changes only what differs from the choice, so a resumed or repeated run redoes
# nothing, and it never installs a package that is already installed.

function Get-AtlasServicingPackageState {
    <#
    .SYNOPSIS
        The servicing state of an Atlas package, from the CBS registry: 'Installed'
        (CurrentState 112), 'InstallPending' (96), 'UninstallPending' (5), or $null when
        no version of it is installed or on its way. With several versions the first of
        those states found wins.
    .NOTES
        The Choices phase decides from Get-AtlasTransitionDefenderPackageState
        (WindowsTransition.ps1), which reads the same values; keep the two in step.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # Tests point these at a scratch key.
        [ValidateNotNull()]
        [Microsoft.Win32.RegistryKey]$BaseKey = [Microsoft.Win32.Registry]::LocalMachine,

        [ValidateNotNullOrEmpty()]
        [string]$PackagesPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
    )

    $packages = $BaseKey.OpenSubKey($PackagesPath, $false)
    if ($null -eq $packages) {
        return $null
    }
    $states = New-Object 'Collections.Generic.List[int]'
    try {
        foreach ($keyName in @($packages.GetSubKeyNames() | Where-Object { $_ -like "$Name~*" })) {
            $package = $packages.OpenSubKey($keyName, $false)
            if ($null -eq $package) { continue }
            try {
                if (@($package.GetValueNames()) -contains 'CurrentState' -and
                    $package.GetValueKind('CurrentState') -eq [Microsoft.Win32.RegistryValueKind]::DWord) {
                    $states.Add([int]$package.GetValue('CurrentState'))
                }
            }
            finally {
                $package.Dispose()
            }
        }
    }
    finally {
        $packages.Dispose()
    }

    if ($states.Contains(112)) { return 'Installed' }
    if ($states.Contains(96)) { return 'InstallPending' }
    if ($states.Contains(5)) { return 'UninstallPending' }
    return $null
}

function Test-AtlasDefenderServicePresent {
    # The WinDefend service key exists while Microsoft Defender is on this PC.
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\WinDefend', $false)
    if ($null -eq $key) {
        return $false
    }
    $key.Dispose()
    return $true
}

function Set-AtlasDefenderChoice {
    <#
    .SYNOPSIS
        Applies the Microsoft Defender choice where this PC differs from it, and returns
        $true when it changed Defender. Disable installs Atlas's NoDefender package and
        turns Defender's core service off at the next startup; Enable puts the core
        service back, then takes off the NoDefender package.
    .DESCRIPTION
        Only Atlas's own package can be taken off: a Defender that is missing without it
        stays missing, with a warning. NoTelemetry goes on with a Defender change when it
        isn't installed. A package still waiting for a restart can't be reversed before
        it: a removal Atlas can't make is a warning, and a Defender it can't bring back
        fails the install.

        -Fresh is for the Components phase, which puts Atlas's components on a Windows
        that has none of them: a first installation, or a Windows that rebuilt itself.
        NoTelemetry then goes on with either choice, and Disable always sets up the core
        service, as the first installation always has.

        Package failures throw. Install-AtlasCbsPackage arms the Safe Mode retry first,
        and a Defender that can't be brought back fails the install, or Atlas would
        report success to a user who chose to keep Defender and has no antivirus.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$State,

        [switch]$Fresh
    )

    $defenderPattern = '*Z-Atlas-NoDefender-Package*'
    $telemetryPattern = '*Z-Atlas-NoTelemetry-Package*'
    $defender = Get-AtlasServicingPackageState -Name 'Z-Atlas-NoDefender-Package'
    # A package waiting for the restart is already on its way; installing it again would
    # only repeat the servicing work.
    $telemetryMissing = (Get-AtlasServicingPackageState -Name 'Z-Atlas-NoTelemetry-Package') -cnotin @('Installed', 'InstallPending')
    $changed = $false

    if ($State -ceq 'Disable') {
        if ($null -eq $defender) {
            $packages = @($defenderPattern)
            if ($telemetryMissing) { $packages += $telemetryPattern }
            Write-AtlasLog -Message "Removing Microsoft Defender with Atlas's NoDefender package."
            Install-AtlasCbsPackage -Packages $packages -NonInteractive | Out-Null
            $telemetryMissing = $false
            $changed = $true
        }
        elseif ($defender -ceq 'UninstallPending') {
            Write-AtlasLog -Level Warning -Message `
                "Atlas's NoDefender package is still waiting for a restart to come off, so Microsoft Defender comes back at the restart and this installation can't remove it. Restart Windows, then use Toggle Defender in the Atlas folder to remove it."
        }
        # CBS doesn't show the core service, so it is read: a run that stopped after the
        # package went on, or an earlier Atlas that never turned it off, left it failing
        # at every startup.
        if ($changed -or ($defender -cin @('Installed', 'InstallPending') -and
                ($Fresh -or -not (Test-AtlasDefenderCoreServiceRemoved)))) {
            Set-AtlasDefenderCoreService -State Removed
        }
    }
    elseif ($defender -ceq 'Installed') {
        # The core service goes back first, while Defender is still removed and Tamper
        # Protection can't refuse the write.
        Write-AtlasLog -Message "Bringing Microsoft Defender back: removing Atlas's NoDefender package."
        Set-AtlasDefenderCoreService -State Restored
        $restore = Uninstall-AtlasCbsPackage -Packages @($defenderPattern)
        if ($telemetryMissing) {
            Install-AtlasCbsPackage -Packages @($telemetryPattern) -NonInteractive | Out-Null
            $telemetryMissing = $false
        }
        if (@($restore.FailedPackages).Count -gt 0) {
            throw "Microsoft Defender couldn't be restored: $(@($restore.FailedPackages) -join ', ')"
        }
        $changed = $true
    }
    elseif ($defender -ceq 'InstallPending') {
        # Defender goes at the restart whatever this run does, so carrying on would
        # report success to a user who chose to keep it.
        throw "Microsoft Defender couldn't be restored: Atlas's NoDefender package is still waiting for a restart to finish installing. Restart Windows, then run the installation again."
    }
    elseif ($null -eq $defender -and -not (Test-AtlasDefenderServicePresent)) {
        Write-AtlasLog -Level Warning -Message `
            "Microsoft Defender isn't on this PC and no Atlas package removed it, so Atlas can't bring it back."
    }

    if ($Fresh -and $telemetryMissing) {
        Install-AtlasCbsPackage -Packages @($telemetryPattern) -NonInteractive | Out-Null
    }
    return $changed
}
