@{
    Name        = 'ToggleWindowsUpdates'
    # Update replay applies the recorded state, so this menu toggle needs no SilentDefault.
    Description = 'Turns Windows Update on or off: its services, scheduled tasks, policies and Settings page.'
    Elevation   = 'TrustedInstaller'
    Warning     = 'Disabling Windows Update also stops Microsoft Store and the Xbox app installing or updating apps and games. Enable usually turns updates back on, but it can fail. To stop updates for a while, use Pause Windows Updates in the General Configuration folder instead.'
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
