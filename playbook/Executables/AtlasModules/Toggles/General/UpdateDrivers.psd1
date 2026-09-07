@{
    Name          = 'UpdateDrivers'
    Description   = 'Run the Update Drivers helper. A plain action launcher that records no state.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Script        = 'UpdateDrivers.ps1'
    States        = @(
        @{
            Name          = 'Run'
            Launcher      = '2. Drivers\Run Update Drivers.cmd'
            Reboot        = 'None'
            MachineAction = 'Invoke-AtlasDriverUpdate'
        }
    )
}
