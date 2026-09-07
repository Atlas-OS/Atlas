@{
    Name          = 'ConfigVBS'
    Description   = 'Shows the current Virtualization-Based Security configuration once; records no state.'
    Elevation     = 'None'
    NoStateRecord = $true
    Script        = 'ConfigVBS.ps1'
    States        = @(
        @{
            Name            = 'Run'
            Launcher        = '7. Security\Core Isolation (VBS)\Current Configuration.cmd'
            ToolboxLauncher = 'Scripts\vbsCurrentConfig.cmd'
            Reboot          = 'None'
            Action          = 'Show-AtlasVbsConfiguration'
        }
    )
}
