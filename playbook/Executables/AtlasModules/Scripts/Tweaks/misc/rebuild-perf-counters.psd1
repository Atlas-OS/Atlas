@{
    Name        = 'Rebuild Performance Counters'
    Description = 'Manually rebuilds performance counters to ensure that there is no issues with them'
    Run         = @(
        # https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/manually-rebuild-performance-counters
        @{ Exe = 'lodctr'; Args = '/r' }
        @{ Exe = 'lodctr'; Args = '/r' }
        @{ Exe = 'winmgmt'; Args = '/resyncperf' }
    )
}
