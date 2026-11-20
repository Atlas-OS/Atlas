@{
    Name          = 'ViewCurrentValues'
    Description   = 'Shows the current boot configuration from `bcdedit /enum {current}`.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Script        = 'ViewCurrentValues.ps1'
    States        = @(
        @{
            Name            = 'View'
            Launcher        = '6. Advanced Configuration\Boot Configuration\View Current Values.cmd'
            ToolboxLauncher = 'Scripts\viewBootValues.cmd'
            Reboot          = 'None'
            MachineAction   = 'Show-AtlasBootValues'
        }
    )
}
