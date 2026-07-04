@{
    Name        = 'Set Taskbar to Align Left'
    Description = 'Sets taskbar to align left instead of centered'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAl'; Type = 'DWord'; Data = 0 }
    )
}
