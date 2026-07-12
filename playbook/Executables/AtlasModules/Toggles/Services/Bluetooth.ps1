# Toggle: Bluetooth (drivers, services, devices, Send To entry, policy).
@{
    Name      = 'Bluetooth'
    Elevation = 'Admin'
    Warning   = 'This script will modify system services and drivers.'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Services\Bluetooth\Disable Bluetooth.cmd'
            Reboot     = 'Recommend'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Write-Host 'Disabling Bluetooth... This might take a minute.'
                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                foreach ($svc in @(
                    'BluetoothUserService', 'BTAGService', 'BthA2dp', 'BthAvctpSvc', 'BthEnum',
                    'BthHFEnum', 'BthLEEnum', 'BthMini', 'BTHMODEM', 'BTHPORT', 'bthserv',
                    'BTHUSB', 'HidBth', 'Microsoft_Bluetooth_AvrcpTransport', 'RFCOMM'
                )) {
                    & $setSvc -Name $svc -Start 4 -AllowMissing
                }
                & $setSvc -Name 'BthPan' -Start 4 -AllowMissing

                $toggleDevice = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-DeviceState.ps1'
                & $toggleDevice -Silent -AllowNoMatch '*Bluetooth*'

                Set-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth' -Name 'value' -Type DWord -Data 0
            }
            UserAction = {
                param($Toggle)

                $sendTo = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SendToContextMenu.ps1'
                & $sendTo -Disable @('Bluetooth')
                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Services\Bluetooth\Enable Bluetooth (default).cmd'
            Reboot     = 'Recommend'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                foreach ($svc in @(
                    'BluetoothUserService', 'BTAGService', 'BthA2dp', 'BthAvctpSvc', 'BthEnum',
                    'BthHFEnum', 'BthLEEnum', 'BthMini', 'BTHMODEM', 'BTHPORT', 'bthserv',
                    'BTHUSB', 'HidBth', 'Microsoft_Bluetooth_AvrcpTransport', 'RFCOMM'
                )) {
                    & $setSvc -Name $svc -Start 3 -AllowMissing
                }
                & $setSvc -Name 'BthPan' -Start 3 -AllowMissing

                $toggleDevice = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-DeviceState.ps1'
                & $toggleDevice -Silent -Enable -AllowNoMatch '*Bluetooth*'

                Set-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth' -Name 'value' -Type DWord -Data 2
            }
            UserAction = {
                param($Toggle)

                $sendTo = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SendToContextMenu.ps1'
                $enableSendTo = $false
                if (-not $Toggle.Silent) {
                    $answer = Read-Host "Would you like to enable the 'Bluetooth File Transfer' Send To context menu entry? [Y/N]"
                    $enableSendTo = ($answer -match '^(y|yes)$')
                }
                if ($enableSendTo) {
                    & $sendTo -Enable @('Bluetooth')
                }
                else {
                    & $sendTo -Disable @('Bluetooth')
                }

                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
        }
    }
}
