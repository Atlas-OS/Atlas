@{
    Name           = 'Disable Modern Standby SleepStudy'
    Description    = 'Turns off the Sleep Study diagnostic logs and the Power Efficiency Diagnostics task, which record standby and power activity in the background.'
    ScheduledTasks = @(
        # This task is absent on systems that do not expose the relevant standby diagnostics.
        @{ Path = '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem'; IgnoreErrors = $true }
    )
    Run            = @(
        @{ Exe = '{windir}\System32\wevtutil.exe'; Args = @('set-log', 'Microsoft-Windows-SleepStudy/Diagnostic', '/e:false') }
        @{ Exe = '{windir}\System32\wevtutil.exe'; Args = @('set-log', 'Microsoft-Windows-Kernel-Processor-Power/Diagnostic', '/e:false') }
        @{ Exe = '{windir}\System32\wevtutil.exe'; Args = @('set-log', 'Microsoft-Windows-UserModePowerService/Diagnostic', '/e:false') }
    )
}
