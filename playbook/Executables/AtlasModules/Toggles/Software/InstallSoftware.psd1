@{
    Name          = 'InstallSoftware'
    Description   = 'Opens the Atlas software picker. Records no state.'
    Elevation     = 'None'
    NoStateRecord = $true
    Script        = 'InstallSoftware.ps1'
    States        = @(
        @{
            Name     = 'Run'
            Launcher = '1. Software\Install Software.cmd'
            Reboot   = 'None'
            Action   = 'Invoke-AtlasSoftwarePicker'
        }
    )
}
