@{
    Name        = 'Use Compact Mode'
    Description = 'Uses compact view in File Explorer, which reduces the space between items.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'UseCompactMode'; Type = 'DWord'; Data = 1 }
    )
}
