# Toggle: Bluetooth (drivers, services, devices, Send To entry, policy).
# Converted from 'AtlasDesktop\6. Advanced Configuration\Services\Bluetooth\*.cmd'.
#
# The source showed the shared service warning on non-silent runs; the engine's Warning
# field reproduces that. Devices are toggled through Internal\ToggleDevice.ps1 and the
# 'Bluetooth' Send To entry through Internal\DebloatSendToContextMenu.ps1.
@{
    Name      = 'Bluetooth'
    Elevation = 'Admin'
    Warning   = 'This script will modify system services and drivers.'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Services\Bluetooth\Disable Bluetooth.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                Write-Host 'Disabling Bluetooth... This might take a minute.'
                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SetServiceStartup.ps1'
                foreach ($svc in @(
                    'BluetoothUserService', 'BTAGService', 'BthA2dp', 'BthAvctpSvc', 'BthEnum',
                    'BthHFEnum', 'BthLEEnum', 'BthMini', 'BTHMODEM', 'BTHPORT', 'bthserv',
                    'BTHUSB', 'HidBth', 'Microsoft_Bluetooth_AvrcpTransport', 'RFCOMM'
                )) {
                    & $setSvc -Name $svc -Start 4
                }
                & $setSvc -Name 'BthPan' -Start 4 2>$null

                $toggleDevice = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\ToggleDevice.ps1'
                & $toggleDevice -Silent '*Bluetooth*'

                $sendTo = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\DebloatSendToContextMenu.ps1'
                & $sendTo -Disable @('Bluetooth')

                $key = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                Set-ItemProperty -LiteralPath $key -Name 'value' -Value 0 -Type DWord -Force

                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Services\Bluetooth\Enable Bluetooth (default).cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SetServiceStartup.ps1'
                foreach ($svc in @(
                    'BluetoothUserService', 'BTAGService', 'BthA2dp', 'BthAvctpSvc', 'BthEnum',
                    'BthHFEnum', 'BthLEEnum', 'BthMini', 'BTHMODEM', 'BTHPORT', 'bthserv',
                    'BTHUSB', 'HidBth', 'Microsoft_Bluetooth_AvrcpTransport', 'RFCOMM'
                )) {
                    & $setSvc -Name $svc -Start 3
                }
                & $setSvc -Name 'BthPan' -Start 3 2>$null

                $toggleDevice = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\ToggleDevice.ps1'
                & $toggleDevice -Silent -Enable '*Bluetooth*'

                $key = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                Set-ItemProperty -LiteralPath $key -Name 'value' -Value 2 -Type DWord -Force

                $sendTo = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\DebloatSendToContextMenu.ps1'
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
