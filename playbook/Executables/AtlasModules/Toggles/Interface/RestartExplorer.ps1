# Toggle: Restart Windows Explorer (plain action, no state recording).
# The engine performs the explorer restart via Reboot='RestartExplorer' (which /noAction
# suppresses), so the action only prints status.
@{
    Name          = 'RestartExplorer'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '4. Interface Tweaks\Restart Explorer.cmd'
            Reboot   = 'RestartExplorer'
            Action   = {
                param($Toggle)

                if (-not $Toggle.Silent) {
                    Write-Host 'Restarting Explorer...' -ForegroundColor Yellow
                }
            }
        }
    }
}
