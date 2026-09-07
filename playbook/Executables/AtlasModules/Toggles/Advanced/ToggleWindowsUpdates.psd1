@{
    Name        = 'ToggleWindowsUpdates'
    Description = 'Windows Update services, scheduled tasks and policies through one menu launcher. Replay resolves the recorded state, so no SilentDefault is needed.'
    Elevation   = 'Admin'
    Menu        = $true
    Launcher    = '6. Advanced Configuration\Toggle Windows Updates\Toggle Windows Updates.cmd'
    Script      = 'ToggleWindowsUpdates.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            MenuLabel     = 'Disable Windows Updates'
            Reboot        = 'Prompt'
            MachineAction = 'Disable-AtlasWindowsUpdates'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            MenuLabel     = 'Enable Windows Updates'
            Reboot        = 'Prompt'
            MachineAction = 'Enable-AtlasWindowsUpdates'
        }
    )
}
