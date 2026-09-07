@{
    Name        = 'SuperFetch'
    Description = 'SuperFetch (SysMain) and ReadyBoost.'
    Elevation   = 'Admin'
    Warning     = 'Changes the SysMain and ReadyBoost services. While disabled, Windows no longer preloads frequently used apps, and ReadyBoost is unavailable.'
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
            ToolboxLauncher = 'Scripts\SuperFetch\EnableSuperFetch.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Set-AtlasSuperFetchMachineState'
        }
    )
}
