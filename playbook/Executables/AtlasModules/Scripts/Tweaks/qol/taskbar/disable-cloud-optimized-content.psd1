@{
    Name        = 'Disable Cloud Optimized Content on Taskbar'
    Description = 'Disables cloud optimized content in the taskbar for QoL, which pins items dependent on things like having linked phone or Xbox Live - seems to break Windows Spotlight'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableCloudOptimizedContent'; Type = 'DWord'; Data = 1 }
    )
}
