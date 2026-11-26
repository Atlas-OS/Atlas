# Companion of set-power-settings.psd1.
$ErrorActionPreference = 'Stop'

$disablePowerSaving = [bool](Test-AtlasOption -Name 'disable-power-saving')
$disableHibernation = [bool](Test-AtlasOption -Name 'disable-hibernation')

# The toggles' machine states apply and record these choices, so the install and the
# AtlasDesktop launchers can't drift apart.
Import-AtlasModule -Name Atlas.Toggles
if ($disablePowerSaving) {
    Invoke-AtlasToggleMachineState -Name PowerSaving -State Disable
}

# Disabling hibernation also makes NTFS accessible outside Windows.
if ($disableHibernation) {
    Invoke-AtlasToggleMachineState -Name Hibernation -State Disable
}

# Keep the Balanced power scheme when power saving is retained. It's restored first
# when Windows doesn't have it; device power saving is left as it is.
if (-not $disablePowerSaving) {
    Import-AtlasModule -Name Atlas.Hardware
    Enable-AtlasBalancedPowerScheme
}
