@{
    Name          = 'RestartExplorer'
    # The engine restarts File Explorer and says so through Reboot = RestartExplorer, so the action
    # itself does nothing. The /noaction switch skips the restart.
    Description   = 'Restarts File Explorer for the signed-in user.'
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
