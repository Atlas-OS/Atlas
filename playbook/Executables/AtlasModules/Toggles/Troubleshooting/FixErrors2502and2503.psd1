@{
    Name          = 'FixErrors2502and2503'
    Description   = 'Fixes installer errors 2502 and 2503 by resetting the Windows TEMP folder permissions. Records no state.'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    Script        = 'FixErrors2502and2503.ps1'
    States        = @(
        @{
            Name            = 'Run'
            Launcher        = '9. Troubleshooting\Fix Errors 2502 and 2503.cmd'
            ToolboxLauncher = 'Scripts\Troubleshooting\Fix Errors 2502 and 2503.cmd'
            Reboot          = 'None'
            MachineAction   = 'Invoke-AtlasWindowsTempPermissionsRepair'
        }
    )
}
