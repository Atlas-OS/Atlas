@{
    Name        = 'Disable ''Notify About USB Issues'''
    Description = 'Disables ''Notify me if there are issues connecting to USB devices'' as this is prone to false positives, for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Shell\USB'; Name = 'NotifyOnUsbErrors'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Shell\USB'; Name = 'NotifyOnWeakCharger'; Type = 'DWord'; Data = 0 }
    )
}
