@{
    Name        = 'Configure Crash Control'
    Description = 'Keeps the stop error (blue screen) on screen with more detail instead of restarting automatically. Windows still writes a 256 KiB minidump and logs the stop code, so crashes stay diagnosable, but skips full memory dumps.'
    Registry    = @(
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'AutoReboot'; Type = 'DWord'; Data = 0 }
        # 3 = small memory dump (a 256 KiB minidump): little disk cost, and !analyze still works.
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'CrashDumpEnabled'; Type = 'DWord'; Data = 3 }
        # Keep the bugcheck event-log record; without it a BSoD leaves no trace at all.
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'LogEvent'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'DisplayParameters'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl\StorageTelemetry'; Name = 'DeviceDumpEnabled'; Type = 'DWord'; Data = 0 }
    )
}
