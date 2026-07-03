# Toggle: Restart Windows Explorer (plain action, no state recording).
# Converted from 'AtlasDesktop\4. Interface Tweaks\Restart Explorer.ps1'.
#
# The original was a loose .ps1 in the user-visible folder (double-click opened Notepad).
# It is replaced by a generated .cmd launcher + this definition; the old .ps1 is removed.
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
