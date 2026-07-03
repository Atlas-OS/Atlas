@{
    Name        = 'Respect Power Modes Windows Search Indexing'
    Description = 'Respects current power mode for indexing to prevent battery drainage'
    Registry    = @(
        @{ Path = 'HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex'; Name = 'RespectPowerModes'; Type = 'DWord'; Data = 1 }
    )
}
