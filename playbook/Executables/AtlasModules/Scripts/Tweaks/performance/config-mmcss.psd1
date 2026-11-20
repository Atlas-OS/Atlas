@{
    Name        = 'Configure the Multimedia Class Scheduler Service'
    Description = 'Lets the Multimedia Class Scheduler Service give games, audio and video playback up to 90% of CPU time, reserving 10% for background tasks instead of 20%.'
    Registry    = @(
        # Reserve 10% (default: 20%) of CPU for non-multimedia background tasks, letting
        # MMCSS-registered threads (games, audio, media playback) use up to 90%.
        # 10 is the lowest value Windows honours; anything lower is clamped back to 20.
        # https://learn.microsoft.com/windows/win32/procthread/multimedia-class-scheduler-service#registry-settings
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Type = 'DWord'; Data = 10 }
    )
}
