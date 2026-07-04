@{
    Name        = 'Configure Crash Control'
    Description = 'Configures the BSoD to show the most useful information on screen while keeping crashes diagnosable: a small (256 KB) minidump and the System-log bugcheck record are kept so crashes can still be triaged, but full memory dumps are not written. The machine stays on the BSoD screen (no auto-reboot) so the stop code can be read.'
    Registry    = @(
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'AutoReboot'; Type = 'DWord'; Data = 0 }
        # 3 = small memory dump (256 KB minidump) - negligible disk cost, keeps !analyze possible.
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'CrashDumpEnabled'; Type = 'DWord'; Data = 3 }
        # Keep the bugcheck event-log record; without it a BSoD leaves no trace at all.
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'LogEvent'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name = 'DisplayParameters'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl\StorageTelemetry'; Name = 'DeviceDumpEnabled'; Type = 'DWord'; Data = 0 }
    )
}
