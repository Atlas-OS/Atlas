# Toggle: Windows Defender (install / uninstall the NoDefender CBS package).
# Converted from 'AtlasDesktop\7. Security\Defender\Toggle Defender.cmd'.
#
# The original relaunched via RunAsTI.cmd using a PATH-relative 'call RunAsTI.cmd' (a latent
# bug when the working directory isn't AtlasModules\Scripts); Elevation='TrustedInstaller'
# routes through the engine's absolute-path RunAsTI wrapper instead. It never recorded an
# AtlasOS\Services state (no settingName), so NoStateRecord preserves that. The real work
# lives in the existing Internal\ToggleDefender.ps1 (it prompts for its own restart).
@{
    Name          = 'ToggleDefender'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '7. Security\Defender\Toggle Defender.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\ToggleDefender.ps1'
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
