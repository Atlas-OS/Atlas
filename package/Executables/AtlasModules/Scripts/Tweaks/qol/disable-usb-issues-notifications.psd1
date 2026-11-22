@{
    Name        = 'Disable ''Notify About USB Issues'''
    Description = 'Turns off notifications about USB connection problems and weak chargers, which often warn about problems that aren''t there.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Shell\USB'; Name = 'NotifyOnUsbErrors'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Shell\USB'; Name = 'NotifyOnWeakCharger'; Type = 'DWord'; Data = 0 }
    )
}
