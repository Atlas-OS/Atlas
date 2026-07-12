# Toggle: Telemetry Components (plain action launcher, no state recording).
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

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Remove-TelemetryComponents.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    throw "Required telemetry-components helper is missing: '$script'."
                }

                & $script
            }
        }
    }
}
