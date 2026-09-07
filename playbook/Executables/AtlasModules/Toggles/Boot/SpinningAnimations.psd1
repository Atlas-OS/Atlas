@{
    Name          = 'SpinningAnimations'
    Description   = 'Boot spinning animation.'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Appearance\Spinning Animation.cmd'
    SilentDefault = 'Enable'
    Script        = 'SpinningAnimations.ps1'
    States        = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            MenuLabel     = 'Disable the spinning animation'
            Reboot        = 'Recommend'
            MachineAction = 'Disable-AtlasSpinningAnimations'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            MenuLabel     = 'Enable the spinning animation (default)'
            Reboot        = 'Recommend'
            MachineAction = 'Enable-AtlasSpinningAnimations'
        }
    )
}
