@{
    Name          = 'AutomaticRepair'
    Description   = 'Windows Automatic Repair at boot (bootstatuspolicy).'
    Elevation     = 'Admin'
    Menu          = $true
    Launcher      = '6. Advanced Configuration\Boot Configuration\Behavior\Automatic Repair.cmd'
    SilentDefault = 'Enable'
    Script        = 'AutomaticRepair.ps1'
    States        = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            MenuLabel     = 'Disable automatic repair'
            Reboot        = 'Recommend'
            MachineAction = 'Disable-AtlasAutomaticRepair'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            MenuLabel     = 'Enable automatic repair (default)'
            Reboot        = 'Recommend'
            MachineAction = 'Enable-AtlasAutomaticRepair'
        }
    )
}
