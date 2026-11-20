@{
    Name        = 'Disable Cloud Optimized Content on Taskbar'
    Description = 'Turns off cloud-optimised content, which adds taskbar pins that depend on things like a linked phone or Xbox Live.'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableCloudOptimizedContent'; Type = 'DWord'; Data = 1 }
    )
}
