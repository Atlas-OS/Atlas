@{
    Name        = 'Use Compact Mode'
    Description = 'Sets compact mode in File Explorer'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the value is harmless
    # on Windows 10, whose Explorer is always compact.
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'UseCompactMode'; Type = 'DWord'; Data = 1 }
    )
}
