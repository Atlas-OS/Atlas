@{
    Name        = 'Disallow Telemetry and Data Collection'
    Description = 'Reduces diagnostic data to the minimum the edition supports and neuters collection at the source (DiagTrack autologger). AllowTelemetry=0 means full-off on editions that support it and clamps to Required elsewhere; the service/autologger disable is what stops collection everywhere.'
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
        # Stop diagnostic log and crash dump uploads even when optional data is on (Win11 21H2+, Pro+).
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDiagnosticLogCollection'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDumpCollection'; Type = 'DWord'; Data = 1 }
        # DisableOneSettingsDownloads deliberately NOT set: OneSettings also delivers
        # consumer Known Issue Rollback configs, and DiagTrack being disabled already
        # covers the delivery path.
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
