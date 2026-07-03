# Components phase.
# Removes Windows components that atlas\components.yml previously carried as YAML
# actions: the Security Center startup item, Smart App Control, Microsoft Edge (option
# gated), OneDrive and the CBS component packages (option gated). Runs as
# TrustedInstaller; CBS package failures throw so AME Wizard halts the install
# (handleExitCodes on the phase call).
#
# Kept in atlas\components.yml (AME-only): the 'iso: only' OfflineSys WdBoot delete.
# Moved to atlas\appx.yml: Edge's !appx family removal (AME's provisioned AppX removal
# is battle-tested where Remove-AppxPackage documented-fails).

Assert-AtlasPrivilege -TrustedInstaller

Import-Module Atlas.Services -Force
Import-Module Atlas.TasksProcs -Force
Import-Module Atlas.Software -Force

$internalRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Internal'

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

    # AppX uninstallation in the script seems to fail, therefore it's not used and the
    # !appx removal in atlas\appx.yml is used instead. Note that AppX Edge is removed
    # from the latest builds of Windows, but people could be running a non-updated version.
    try {
        & (Join-Path -Path $internalRoot -ChildPath 'RemoveEdge.ps1') -UninstallEdge -RemoveEdgeData -KeepAppX -NonInteractive
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Removing Microsoft Edge failed: $($_.Exception.Message)"
    }

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
