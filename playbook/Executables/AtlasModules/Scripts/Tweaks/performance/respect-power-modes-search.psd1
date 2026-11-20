@{
    Name        = 'Respect Power Modes Windows Search Indexing'
    Description = 'Makes Windows Search indexing follow the current power mode, so it backs off in power-saving modes instead of draining the battery.'
    Registry    = @(
        @{ Path = 'HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex'; Name = 'RespectPowerModes'; Type = 'DWord'; Data = 1 }
    )
}
