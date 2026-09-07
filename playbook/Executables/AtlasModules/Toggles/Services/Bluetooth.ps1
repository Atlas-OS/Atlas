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
