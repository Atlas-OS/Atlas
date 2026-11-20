@{
    Name          = 'HighestMode'
    Description   = 'Makes boot applications use the highest graphics mode the display supports.'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Behavior\Highest Mode.cmd'
    SilentDefault = 'Disable'
    Script        = 'HighestMode.ps1'
    States        = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            MenuLabel     = 'Disable (default)'
            Reboot        = 'Recommend'
            MachineAction = 'Disable-AtlasHighestMode'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            MenuLabel     = 'Enable'
            Reboot        = 'Recommend'
            MachineAction = 'Enable-AtlasHighestMode'
        }
    )
}
