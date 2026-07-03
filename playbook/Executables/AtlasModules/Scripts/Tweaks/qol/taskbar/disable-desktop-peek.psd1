@{
    Name        = 'Disable Show Desktop Peek on Taskbar'
    Description = 'Disables the ''Show Desktop'' peek feature on the taskbar, as most of the time people accidentally trigger it, so it is disabled here for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'DisablePreviewDesktop'; Type = 'DWord'; Data = 1 }
    )
}
