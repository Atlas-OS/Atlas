@{
    Name          = 'RestartExplorer'
    Description   = 'Restarts File Explorer for the signed-in user; /noaction skips the restart. The engine performs and announces the restart through Reboot = RestartExplorer, so the action itself does nothing. Records no state.'
    Elevation     = 'None'
    NoStateRecord = $true
    Script        = 'RestartExplorer.ps1'
    States        = @(
        @{
            Name     = 'Run'
            Launcher = '4. Interface Tweaks\Restart Explorer.cmd'
            Reboot   = 'RestartExplorer'
            Action   = 'Show-AtlasRestartExplorerMessage'
        }
    )
}
