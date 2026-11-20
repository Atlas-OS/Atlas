@{
    Name          = 'UpdateDrivers'
    Description   = 'Finds driver updates on Microsoft Update and installs the ones you choose.'
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
