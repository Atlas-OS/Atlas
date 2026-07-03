@{
    Name        = 'Configure Crash Control'
    Description = 'Configures the BSoD for having the most useful information and not leaving behind dumps (which most people will not look into anyways)'
    Registry    = @(
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'AutoReboot'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'CrashDumpEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'LogEvent'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'DisplayParameters'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl\StorageTelemetry'; Name = 'DeviceDumpEnabled'; Type = 'DWord'; Data = 0 }
    )
}
