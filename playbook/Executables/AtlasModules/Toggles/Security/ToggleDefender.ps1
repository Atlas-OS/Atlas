# Toggle: Windows Defender (install / uninstall the NoDefender CBS package).
#
# The real work lives in Internal\Set-DefenderState.ps1 (it prompts for its own restart).
@{
    Name          = 'ToggleDefender'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher        = '7. Security\Defender\Toggle Defender.cmd'
            ToolboxLauncher = 'Scripts\toggleDefender.cmd'
            Reboot          = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-DefenderState.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                $scriptArgs = @()
                if ($Toggle.Silent) { $scriptArgs += '/silent' }
                & $script @scriptArgs
            }
        }
    }
}
