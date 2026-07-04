# Components phase.
# Removes Windows components: the Security Center startup item, Smart App Control,
# Microsoft Edge (option gated), OneDrive and the CBS component packages (option
# gated). Runs as TrustedInstaller; CBS package failures throw so AME Wizard halts
# the install (handleExitCodes on the phase call).
#
# Not handled here: the 'iso: only' OfflineSys WdBoot delete (AME-only, in
# atlas\components.yml) and Edge's !appx family removal (in atlas\appx.yml - AME's
# provisioned AppX removal is battle-tested where Remove-AppxPackage documented-fails).

Assert-AtlasPrivilege -TrustedInstaller

Import-Module Atlas.Services -Force
Import-Module Atlas.TasksProcs -Force
Import-Module Atlas.Software -Force

# Remove Security Center startup item
Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'SecurityHealth' -Force -ErrorAction SilentlyContinue

# Disable Smart App Control
# Causes slow app loading issues and sends data to Microsoft
$ciPolicyKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy'
if (-not (Test-Path -LiteralPath $ciPolicyKey)) {
    New-Item -Path $ciPolicyKey -Force | Out-Null
}
Set-ItemProperty -LiteralPath $ciPolicyKey -Name 'VerifiedAndReputablePolicyState' -Value 0 -Type DWord -Force

# Microsoft Edge
if (Test-AtlasOption -Name 'uninstall-edge') {
    $edgeServices = @('edgeupdate', 'edgeupdatem', 'MicrosoftEdgeUpdate', 'MicrosoftEdgeElevationService')
    foreach ($service in $edgeServices) {
        Stop-AtlasService -Name $service
    }
    foreach ($service in $edgeServices) {
        Set-AtlasServiceStartup -Name $service -StartupType 4
    }

    Remove-AtlasScheduledTask -Path 'MicrosoftEdgeUpdateTaskMachineCore' -IgnoreMissing
    Remove-AtlasScheduledTask -Path 'MicrosoftEdgeUpdateTaskMachineUA' -IgnoreMissing

    # Remove-Edge.ps1 runs from atlas\components.yml as the elevated interactive user
    # (it refuses SYSTEM/TrustedInstaller). This phase only handles the pieces that
    # need TrustedInstaller: services, scheduled tasks and the deprovision keys.
    # Edge's AppX removal is the !appx action in atlas\appx.yml.

    foreach ($deprovisionKey in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
    )) {
        New-Item -Path $deprovisionKey -Force | Out-Null
    }
}

# OneDrive
# The actual OneDrive setup in Windows is stripped at a component-level in the miscellaneous package
try {
    Remove-AtlasOneDrive
}
catch {
    Write-AtlasLog -Level Warning -Message "Removing OneDrive failed: $($_.Exception.Message)"
}

# Windows components and Telemetry (CBS packages)
# Install-AtlasCbsPackage throws on failure after registering the Safe Mode retry
# fallback, making this phase exit non-zero so AME Wizard halts.
if (Test-AtlasOption -Name 'defender-disable') {
    Install-AtlasCbsPackage -Packages @(
        '*Z-Atlas-NoDefender-Package*',
        '*Z-Atlas-NoTelemetry-Package*'
    ) -NonInteractive | Out-Null
}
if (Test-AtlasOption -Name 'defender-enable') {
    Uninstall-AtlasCbsPackage -Packages @('*Z-Atlas-NoDefender-Package*') | Out-Null
    Install-AtlasCbsPackage -Packages @('*Z-Atlas-NoTelemetry-Package*') -NonInteractive | Out-Null
}
