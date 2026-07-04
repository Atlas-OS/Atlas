@{
    Name        = 'Rebuild Performance Counters'
    Description = 'Manually rebuilds performance counters to ensure that there is no issues with them'
    Run         = @(
        # The documented procedure rebuilds from BOTH directories: System32 for 64-bit
        # counters and SysWOW64 for the separate 32-bit (WOW64) perflib.
        # https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/manually-rebuild-performance-counters
        @{ Exe = '{windir}\System32\lodctr.exe'; Args = '/R' }
        @{ Exe = '{windir}\SysWOW64\lodctr.exe'; Args = '/R' }
        @{ Exe = 'winmgmt'; Args = '/resyncperf' }
    )
}
