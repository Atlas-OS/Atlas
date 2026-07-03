@{
    Name        = 'Hide Disabled and Disconnected Devices in Sounds Panel'
    Description = 'Hides disabled and disconnected devices in the sounds panel (mmsys.cpl) for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl'; Name = 'ShowDisconnectedDevices'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl'; Name = 'ShowHiddenDevices'; Type = 'DWord'; Data = 0 }
    )
}
