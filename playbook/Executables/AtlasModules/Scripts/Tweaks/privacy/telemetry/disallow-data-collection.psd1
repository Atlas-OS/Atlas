@{
    Name        = 'Disallow Telemetry and Data Collection'
    Description = 'Disallows telemetry and data collection to improve privacy'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack'; Name = 'ShowedToastAtLevel'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'AllowTelemetry'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'MaxTelemetryAllowed'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'AllowTelemetry'; Type = 'DWord'; Data = 0 }
        # Misc
        @{ Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack\EventTranscriptKey'; Name = 'EnableEventTranscript'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack\EventTranscriptKey'; Name = 'MiniTraceSlotEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowDeviceNameInTelemetry'; Type = 'DWord'; Data = 0 }
        # Disable & clear logger
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Diagtrack-Listener'; Name = 'Start'; Type = 'DWord'; Data = 0 }
    )
    Services    = @(
        # Stop DiagTrack service to add the changes
        @{ Name = 'DiagTrack'; Operation = 'Stop' }
    )
    Run         = @(
        @{ Exe = 'cmd.exe'; Args = '/c del "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\DiagTrack*" "%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\DiagTrack*" > nul 2>&1' }
    )
}
