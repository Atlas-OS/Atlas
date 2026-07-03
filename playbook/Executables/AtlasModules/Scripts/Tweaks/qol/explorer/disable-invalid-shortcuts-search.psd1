@{
    Name        = 'Disable Searching for Invalid Shortcuts'
    Description = 'Disables searching drives or using NTFS file system tracking for shortcuts that have invalid/non-existent paths for responsiveness'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoResolveSearch'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoResolveTrack'; Type = 'DWord'; Data = 1 }
    )
}
