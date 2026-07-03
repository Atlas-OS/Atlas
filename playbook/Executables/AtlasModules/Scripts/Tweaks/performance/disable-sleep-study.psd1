@{
    Name           = 'Disable Modern Standby SleepStudy'
    Description    = 'Disables Modern Standby''s SleepStudy feature, as it''s unnecessary logging that isn''t needed on boot'
    ScheduledTasks = @(
        @{ Path = '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem' }
    )
    Run            = @(
        @{ Exe = 'wevtutil.exe'; Args = 'set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false' }
        @{ Exe = 'wevtutil.exe'; Args = 'set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false' }
        @{ Exe = 'wevtutil.exe'; Args = 'set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false' }
    )
}
