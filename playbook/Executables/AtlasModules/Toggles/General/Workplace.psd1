@{
    Name        = 'Workplace'
    # Only an interactive Enable opens the Settings page.
    Description = 'Shows or hides the Access work or school page in Settings.'
    Elevation   = 'Admin'
    Warning     = 'Hides or shows the Access work or school page in Settings. While it''s hidden, you can''t join this PC to a work or school account from Settings.'
    Script      = 'Workplace.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\Workplace\Disable Workplace.cmd'
            Reboot        = 'None'
            MachineAction = 'Hide-AtlasWorkplaceSettingsPage'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\Workplace\Enable Workplace.cmd'
            Reboot        = 'None'
            MachineAction = 'Show-AtlasWorkplaceSettingsPage'
        }
    )
}
