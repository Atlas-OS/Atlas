@{
    Name        = 'Rebuild Performance Counters'
    Description = 'Rebuilds the performance counters from the system files, which repairs corrupt counters that monitoring tools rely on.'
    Run         = @(
        # The documented procedure rebuilds from BOTH directories: System32 for 64-bit
        # counters and SysWOW64 for the separate 32-bit (WOW64) perflib.
        # https://learn.microsoft.com/troubleshoot/windows-server/performance/manually-rebuild-performance-counters
        @{ Exe = '{windir}\System32\lodctr.exe'; Args = @('/R') }
        @{ Exe = '{windir}\SysWOW64\lodctr.exe'; Args = @('/R') }
        @{ Exe = '{windir}\System32\wbem\winmgmt.exe'; Args = @('/resyncperf') }
    )
}
