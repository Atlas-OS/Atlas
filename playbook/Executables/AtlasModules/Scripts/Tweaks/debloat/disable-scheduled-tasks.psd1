@{
    Name           = 'Disable Scheduled Tasks'
    Description    = 'Disables scheduled tasks to prevent automatic tasks from running at startup, consuming resources and collecting user data'
    Registry       = @(
        # Remove from automatic maintenance
        @{ Path = 'HKLM\System\CurrentControlSet\Control\Ubpm'; Name = 'CriticalMaintenance_UsageDataReporting'; Operation = 'Delete' }
    )
    ScheduledTasks = @(
        # PCA's task is handled with its service by privacy/disable-pca.psd1.
        # Data collection
        @{ Path = '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector' }
        # CEIP - safety measure
        @{ Path = '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator' }
        @{ Path = '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip' }
        # A/B testing usage reports
        @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting' }
        # SQM/CEIP proxy that stays Ready after the other CEIP tasks are disabled
        @{ Path = '\Microsoft\Windows\Autochk\Proxy' }
    )
}
