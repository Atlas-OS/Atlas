@{
    Name           = 'Disable Scheduled Tasks'
    Description    = 'Disables scheduled tasks to prevent automatic tasks from running at startup, consuming resources and collecting user data'
    Registry       = @(
        # Remove from automatic maintenance
        @{ Path = 'HKLM\System\CurrentControlSet\Control\Ubpm'; Name = 'CriticalMaintenance_UsageDataReporting'; Operation = 'Delete' }
    )
    ScheduledTasks = @(
        # Updates compatibility database
        @{ Path = '\Microsoft\Windows\Application Experience\PcaPatchDbTask'; IgnoreErrors = $true }
        # Data collection
        @{ Path = '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'; IgnoreErrors = $true }
        # CEIP - safety measure
        @{ Path = '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'; IgnoreErrors = $true }
        @{ Path = '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'; IgnoreErrors = $true }
        # A/B testing usage reports
        @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting'; IgnoreErrors = $true }
        # SQM/CEIP proxy that stays Ready after the other CEIP tasks are disabled
        @{ Path = '\Microsoft\Windows\Autochk\Proxy'; IgnoreErrors = $true }
    )
}
