@{
    Name          = 'RestartExplorer'
    Description   = 'Restart Windows Explorer. The engine performs the restart through Reboot = RestartExplorer (which /noaction suppresses), so the action only prints status and no state is recorded.'
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
