@{
    Name        = 'PowerSaving'
    Description = 'Turns power saving on or off. Disable applies the Atlas power settings for when the PC is plugged in and stops Windows turning off any device to save power; Enable restores the earlier power plan, or Balanced when none was saved, and lets Windows turn off every device to save power again.'
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
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\Power-saving\Default Power-saving (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Invoke-AtlasPowerSavingToggle'
        }
    )
}
