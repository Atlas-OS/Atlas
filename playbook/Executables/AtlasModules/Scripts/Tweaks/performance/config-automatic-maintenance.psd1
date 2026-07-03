@{
    Name        = 'Configure Automatic Maintenance'
    Description = 'Configure the ''Automatic Maintenance'' feature in Windows'
    Registry    = @(
        # Automatic maintenance is needed for auto-defrag/TRIM and more
        # - !registryValue:
        #   path: 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance'
        #   value: 'MaintenanceDisabled'
        #   data: '1'
        #   type: REG_DWORD
        # - !registryValue:
        #   path: 'HKLM\SOFTWARE\Microsoft\Windows\ScheduledDiagnostics'
        #   value: 'EnabledExecution'
        #   data: '0'
        #   type: REG_DWORD
        # https://www.elevenforum.com/t/enable-or-disable-automatic-maintenance-to-wake-up-computer-in-windows-11.16690/
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance'; Name = 'WakeUp'; Type = 'DWord'; Data = 0 }
    )
}
