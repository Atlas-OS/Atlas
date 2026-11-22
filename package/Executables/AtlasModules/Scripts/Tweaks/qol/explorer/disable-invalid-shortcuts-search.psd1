@{
    Name        = 'Disable Searching for Invalid Shortcuts'
    Description = 'Stops Windows searching drives or using NTFS link tracking to repair shortcuts whose target has moved, so a broken shortcut fails straight away.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoResolveSearch'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoResolveTrack'; Type = 'DWord'; Data = 1 }
    )
}
