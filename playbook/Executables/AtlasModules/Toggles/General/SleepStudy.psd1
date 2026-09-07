@{
    Name        = 'SleepStudy'
    Description = 'Sleep Study diagnostic event logs and the Power Efficiency Diagnostics scheduled task.'
    Elevation   = 'Admin'
    Script      = 'SleepStudy.ps1'
    States      = @(
        @{
            Name           = 'Disable'
            StateValue     = 0
            Launcher       = '3. General Configuration\Sleep Study\Disable Sleep Study (default).cmd'
            Reboot         = 'None'
            ScheduledTasks = @(
                @{ Path = '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem'; Operation = 'Disable' }
            )
            MachineAction  = 'Set-AtlasSleepStudyEventLogState'
        }
        @{
            Name           = 'Enable'
            StateValue     = 1
            Launcher       = '3. General Configuration\Sleep Study\Enable Sleep Study.cmd'
            Reboot         = 'None'
            ScheduledTasks = @(
                @{ Path = '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem'; Operation = 'Enable' }
            )
            MachineAction  = 'Set-AtlasSleepStudyEventLogState'
        }
    )
}
