@{
    Name        = 'Disable Shared Experiences'
    Description = 'Disables ''Shared Experiences'', which is a way of sharing items between devices for privacy and QoL'
    Registry    = @(
        # https://www.elevenforum.com/t/turn-on-or-off-nearby-sharing-in-windows-11.2644/
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage'; Name = 'BluetoothLastDisabledNearShare'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\CDP'; Name = 'NearShareChannelUserAuthzPolicy'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\CDP'; Name = 'CdpSessionUserAuthzPolicy'; Type = 'DWord'; Data = 1 }
    )
}
