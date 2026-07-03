@{
    Name        = 'Hide ''Meet Now'' on Taskbar'
    Description = 'Hides ''Meet Now'' on the taskbar for QoL and privacy (as it is an online feature)'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'HideSCAMeetNow'; Type = 'DWord'; Data = 1 }
    )
}
