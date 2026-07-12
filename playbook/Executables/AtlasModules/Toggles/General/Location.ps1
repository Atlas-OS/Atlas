# Toggle: Location services (lfsvc / MapsBroker) and Find My Device.
#
# The Enable path's "Unlock Find My Device" prompt is interactive-only so silent/upgrade
# re-apply never hangs; in silent mode Find My Device is left disabled.
@{
    Name      = 'Location'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Location\Disable Location (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $machineStateHelper = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Internal',
                    'Set-AtlasLocationMachineState.ps1'
                )
                & $machineStateHelper -State Disable
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
                        -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
                    -Force -ErrorAction Stop

                $consent = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
                Set-AtlasRegistryValue -Path $consent -Name 'ShowGlobalPrompts' `
                    -Type DWord -Data 0

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Location services have been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Location\Enable Location.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $machineStateHelper = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Internal',
                    'Set-AtlasLocationMachineState.ps1'
                )
                & $machineStateHelper -State Enable

                if (-not $Toggle.Silent) {
                    Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
                            -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
                        -Force -ErrorAction Stop
                    $settingsPages = [IO.Path]::Combine(
                        $Toggle.ScriptsPath,
                        'Internal',
                        'Set-SettingsPageVisibility.ps1'
                    )
                    $findMyDevice = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
                    $answer = Read-Host 'Would you like to unlock Find My Device functionality? [Y/N]'
                    if ($answer -match '^(y|yes)$') {
                        Remove-AtlasRegistryKey -Path $findMyDevice
                        & $settingsPages unhide findmydevice -Silent
                    }
                    else {
                        Set-AtlasRegistryValue -Path $findMyDevice -Name 'AllowFindMyDevice' `
                            -Type DWord -Data 0
                        Set-AtlasRegistryValue -Path $findMyDevice -Name 'LocationSyncEnabled' `
                            -Type DWord -Data 0
                    }

                    Write-Host ''
                    Write-Host 'Location services have been enabled.'
                    Start-Process 'ms-settings:privacy-location' -ErrorAction Stop
                }
            }
        }
    }
}
