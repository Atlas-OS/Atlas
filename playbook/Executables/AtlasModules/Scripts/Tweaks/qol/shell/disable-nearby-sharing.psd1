@{
    Name        = 'Disable Shared Experiences'
    Description = 'Turns off Shared experiences and Nearby sharing, which share content with nearby devices.'
    Registry    = @(
        # Microsoft does not document these values. Community source:
        # https://www.elevenforum.com/t/turn-on-or-off-nearby-sharing-in-windows-11.2644/
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage'; Name = 'BluetoothLastDisabledNearShare'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\CDP'; Name = 'NearShareChannelUserAuthzPolicy'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\CDP'; Name = 'CdpSessionUserAuthzPolicy'; Type = 'DWord'; Data = 1 }
    )
}
