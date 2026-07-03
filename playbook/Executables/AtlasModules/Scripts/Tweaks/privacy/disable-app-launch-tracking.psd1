@{
    Name        = 'Disable App Launch Tracking'
    Description = 'Prevents Windows from automatically tracking applications you use the most for improved privacy'
    Registry    = @(
        # https://www.tenforums.com/tutorials/82967-turn-off-app-launch-tracking-windows-10-a.html
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Type = 'DWord'; Data = 0 }
    )
}
