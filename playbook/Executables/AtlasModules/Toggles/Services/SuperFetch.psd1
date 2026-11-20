@{
    Name        = 'SuperFetch'
    Description = 'Turns SuperFetch (SysMain) and ReadyBoost on or off.'
    Elevation   = 'Admin'
    Warning     = 'Changes the SysMain and ReadyBoost services. While disabled, Windows doesn''t preload frequently used apps, and ReadyBoost isn''t available.'
    Script      = 'SuperFetch.ps1'
    States      = @(
        @{
            Name            = 'Disable'
            StateValue      = 0
            Launcher        = '6. Advanced Configuration\Services\Superfetch\Disable SuperFetch.cmd'
            ToolboxLauncher = 'Scripts\SuperFetch\DisableSuperFetch.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Set-AtlasSuperFetchMachineState'
        }
        @{
            Name            = 'Enable'
            StateValue      = 1
            Launcher        = '6. Advanced Configuration\Services\Superfetch\Enable SuperFetch (default).cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Set-AtlasSuperFetchMachineState'
        }
    )
}
