@{
    Name        = 'Bluetooth'
    Description = 'Bluetooth drivers, services, devices, the Send To entry and the connectivity policy.'
    Elevation   = 'Admin'
    Warning     = 'Changes the Bluetooth services and drivers and disables or enables every Bluetooth device. While disabled, Bluetooth devices stop working.'
    Script      = 'Bluetooth.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '6. Advanced Configuration\Services\Bluetooth\Disable Bluetooth.cmd'
            Reboot        = 'Recommend'
            Registry      = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth'; Name = 'value'; Type = 'DWord'; Data = 0 }
            )
            Services      = @(
                @{ Name = 'BluetoothUserService'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BTAGService'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BthA2dp'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BthAvctpSvc'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BthEnum'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BthHFEnum'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BthLEEnum'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BthMini'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BTHMODEM'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BTHPORT'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'bthserv'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BTHUSB'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'HidBth'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'Microsoft_Bluetooth_AvrcpTransport'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'RFCOMM'; StartupType = 4; AllowMissing = $true }
                @{ Name = 'BthPan'; StartupType = 4; AllowMissing = $true }
            )
            MachineAction = 'Disable-AtlasBluetoothDevices'
            UserAction    = 'Remove-AtlasBluetoothSendTo'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '6. Advanced Configuration\Services\Bluetooth\Enable Bluetooth (default).cmd'
            Reboot        = 'Recommend'
            Registry      = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\AllowBluetooth'; Name = 'value'; Type = 'DWord'; Data = 2 }
            )
            Services      = @(
                @{ Name = 'BluetoothUserService'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BTAGService'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BthA2dp'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BthAvctpSvc'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BthEnum'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BthHFEnum'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BthLEEnum'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BthMini'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BTHMODEM'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BTHPORT'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'bthserv'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BTHUSB'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'HidBth'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'Microsoft_Bluetooth_AvrcpTransport'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'RFCOMM'; StartupType = 3; AllowMissing = $true }
                @{ Name = 'BthPan'; StartupType = 3; AllowMissing = $true }
            )
            MachineAction = 'Enable-AtlasBluetoothDevices'
            UserAction    = 'Set-AtlasBluetoothSendTo'
        }
    )
}
