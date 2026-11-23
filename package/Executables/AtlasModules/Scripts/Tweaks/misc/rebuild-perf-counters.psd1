@{
    Name        = 'Rebuild Performance Counters'
    Description = 'Attempts to rebuild the performance counters that monitoring tools rely on and logs a warning if Windows cannot complete the repair.'
    Run         = @(
        # The documented procedure rebuilds from BOTH directories: System32 for 64-bit
        # counters and SysWOW64 for the separate 32-bit (WOW64) perflib.
        # https://learn.microsoft.com/troubleshoot/windows-server/performance/manually-rebuild-performance-counters
        # Missing or damaged counter backups should not block installing Atlas.
        @{ Exe = '{windir}\System32\lodctr.exe'; Args = @('/R'); IgnoreErrors = $true }
        @{ Exe = '{windir}\SysWOW64\lodctr.exe'; Args = @('/R'); IgnoreErrors = $true }
        @{ Exe = '{windir}\System32\wbem\winmgmt.exe'; Args = @('/resyncperf'); IgnoreErrors = $true }
    )
}
