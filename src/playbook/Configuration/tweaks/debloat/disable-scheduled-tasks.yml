---
title: Disable Scheduled Tasks
description: Disables scheduled tasks to prevent automatic tasks from running at startup, consuming resources and collecting user data
actions:
    # Updates compatibility database
  - !scheduledTask: {path: '\Microsoft\Windows\Application Experience\PcaPatchDbTask', operation: disable, ignoreErrors: true}

    # UCPD - might not exist on all installs, so ignore errors
  - !scheduledTask: {path: '\Microsoft\Windows\AppxDeploymentClient\UCPD velocity', operation: disable, ignoreErrors: true}

    # Data collection
  - !scheduledTask: {path: '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector', operation: disable, ignoreErrors: true}

    # CEIP - safety measure
  - !scheduledTask: {path: '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator', operation: disable, ignoreErrors: true}
  - !scheduledTask: {path: '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip', operation: disable, ignoreErrors: true} 

    # A/B testing usage reports
  - !scheduledTask: {path: '\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting', operation: disable, ignoreErrors: true}
  - !registryValue:
    path: 'HKLM\System\CurrentControlSet\Control\Ubpm'
    value: 'CriticalMaintenance_UsageDataReporting' # Remove from automatic maintenance
    operation: delete
