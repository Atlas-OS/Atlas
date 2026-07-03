@{
    Name        = 'Use Compact Mode'
    Description = 'Sets compact mode in File Explorer'
    MinBuild    = 22000
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'UseCompactMode'; Type = 'DWord'; Data = 1 }
    )
}
