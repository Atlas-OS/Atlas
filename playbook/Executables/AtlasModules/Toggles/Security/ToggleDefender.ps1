# Toggle: Windows Defender (install / uninstall the NoDefender CBS package).
#
# Set-DefenderState.ps1 prompts for its own restart, so Reboot stays 'None'.
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
                    throw "Required Defender state helper is missing: '$script'."
                }

                $scriptArgs = @()
                if ($Toggle.Silent) { $scriptArgs += '/silent' }
                & $script @scriptArgs
            }
        }
    }
}
