# Toggle: Telemetry Components (plain action launcher, no state recording).
# Converted from 'AtlasDesktop\9. Troubleshooting\Telemetry Components.cmd', which ran as
# TrustedInstaller and thinly launched 'ScriptWrappers\TelemetryComponents.ps1'
# (a passthrough to 'Internal\TelemetryComponents.ps1').
@{
    Name          = 'TelemetryComponents'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher        = '9. Troubleshooting\Telemetry Components.cmd'
            ToolboxLauncher = 'Scripts\Troubleshooting\Telemetry Components.cmd'
            Reboot          = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\TelemetryComponents.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script
            }
        }
    }
}
