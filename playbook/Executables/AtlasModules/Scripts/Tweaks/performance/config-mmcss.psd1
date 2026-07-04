@{
    Name        = 'Configure the Multimedia Class Scheduler Service'
    Description = 'Configures MMCSS for the best performance'
    Registry    = @(
        # Reserve 10% (default: 20%) of CPU for non-multimedia background tasks, letting
        # MMCSS-registered threads (games, audio, media playback) use up to 90%.
        # 10 is the lowest honored value - anything below is clamped back to 20.
        # https://learn.microsoft.com/en-us/windows/win32/procthread/multimedia-class-scheduler-service#registry-settings
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Type = 'DWord'; Data = 10 }
    )
}
