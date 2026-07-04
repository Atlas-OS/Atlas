@{
    Name        = 'Use Compact Mode'
    Description = 'Sets compact mode in File Explorer'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'UseCompactMode'; Type = 'DWord'; Data = 1 }
    )
}
