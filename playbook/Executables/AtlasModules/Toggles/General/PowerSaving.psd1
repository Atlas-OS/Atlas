@{
    Name        = 'PowerSaving'
    Description = 'Power-saving: the documented Atlas AC power policy versus the prior power plan. Both states use the same helper.'
    Elevation   = 'Admin'
    Script      = 'PowerSaving.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\Power-saving\Disable Power-saving.cmd'
            Reboot        = 'None'
            MachineAction = 'Invoke-AtlasPowerSavingToggle'
        }
        @{
            Name          = 'Default'
            StateValue    = 1
            Launcher      = '3. General Configuration\Power-saving\Default Power-saving (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Invoke-AtlasPowerSavingToggle'
        }
    )
}
