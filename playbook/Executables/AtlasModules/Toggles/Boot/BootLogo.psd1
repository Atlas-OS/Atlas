@{
    Name          = 'BootLogo'
    Description   = 'Windows boot logo.'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Appearance\Boot Logo.cmd'
    SilentDefault = 'Enable'
    Script        = 'BootLogo.ps1'
    States        = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            MenuLabel     = 'Disable the boot logo'
            Reboot        = 'Recommend'
            MachineAction = 'Disable-AtlasBootLogo'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            MenuLabel     = 'Enable the boot logo (default)'
            Reboot        = 'Recommend'
            MachineAction = 'Enable-AtlasBootLogo'
        }
    )
}
