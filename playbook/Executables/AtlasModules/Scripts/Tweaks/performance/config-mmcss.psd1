@{
    Name        = 'Configure the Multimedia Class Scheduler Service'
    Description = 'Configures MMCSS for the best performance'
    Registry    = @(
        # Set system responsiveness to 10%
        # Allocates less CPU resources to tasks that request it such as browsers, so that other applications will not be impacted as much
        # https://learn.microsoft.com/en-us/windows/win32/procthread/multimedia-class-scheduler-service#registry-settings
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Type = 'DWord'; Data = 10 }
    )
}
