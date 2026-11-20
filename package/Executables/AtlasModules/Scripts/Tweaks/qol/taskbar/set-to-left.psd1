@{
    Name        = 'Set Taskbar to Align Left'
    Description = 'Aligns the taskbar to the left instead of the centre.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAl'; Type = 'DWord'; Data = 0 }
    )
}
