@{
    Name          = 'RemoveEdge'
    Description   = 'Install or remove Microsoft Edge through its interactive helper, hosted in the administrator window the engine opens. Records no state.'
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
