# Companion for the Bluetooth toggle: disables or enables every Bluetooth device and removes
# or restores the Bluetooth Send to entry. The device functions run as Administrator when you
# run a launcher and when an update replays the recorded state. The Send to functions run in
# your own unelevated process afterwards, and is replayed for each new account at first
# sign-in.

function Disable-AtlasBluetoothDevices {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Disabling Bluetooth devices. This can take a minute...'
    }
    Import-AtlasModule -Name Atlas.Hardware
    Set-AtlasDeviceState -State Disable -Devices '*Bluetooth*' -AllowNoMatch -Silent
}

function Enable-AtlasBluetoothDevices {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Enabling Bluetooth devices...'
    }
    Import-AtlasModule -Name Atlas.Hardware
    Set-AtlasDeviceState -State Enable -Devices '*Bluetooth*' -AllowNoMatch -Silent
}

function Remove-AtlasBluetoothSendTo {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSendToContextMenu -Disable @('Bluetooth')
}

function Set-AtlasBluetoothSendTo {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    $enableSendTo = $false
    if (-not $Toggle.Silent) {
        $enableSendTo = Read-AtlasYesNo -Question "Add 'Bluetooth File Transfer' to the Send To context menu?"
    }
    if ($enableSendTo) {
        Set-AtlasSendToContextMenu -Enable @('Bluetooth')
    }
    else {
        Set-AtlasSendToContextMenu -Disable @('Bluetooth')
    }
}
