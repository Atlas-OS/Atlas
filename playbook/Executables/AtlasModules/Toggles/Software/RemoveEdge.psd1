@{
    Name          = 'RemoveEdge'
    Description   = 'Installs or removes Microsoft Edge through an interactive helper in an administrator window.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Script        = 'RemoveEdge.ps1'
    States        = @(
        @{
            Name          = 'Run'
            Launcher      = '1. Software\Install or Remove Edge.cmd'
            Reboot        = 'None'
            MachineAction = 'Invoke-AtlasEdgeRemover'
        }
    )
}
