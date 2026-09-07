@{
    Name          = 'NewBootMenu'
    Description   = 'New (Windows 8+) boot menu versus the legacy Windows 7 boot menu.'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Appearance\New Boot Menu.cmd'
    SilentDefault = 'Disable'
    Script        = 'NewBootMenu.ps1'
    States        = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            MenuLabel     = 'Disable the new boot menu (default)'
            Reboot        = 'Recommend'
            MachineAction = 'Disable-AtlasNewBootMenu'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            MenuLabel     = 'Enable the new boot menu'
            Reboot        = 'Recommend'
            MachineAction = 'Enable-AtlasNewBootMenu'
        }
    )
}
