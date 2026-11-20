@{
    Name          = 'TelemetryComponents'
    # The menu runs in the administrator window, and its choice reaches the silent TrustedInstaller
    # broker as a fixed internal state.
    Description   = 'Adds or removes the Atlas NoTelemetry package, which removes Windows telemetry components.'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    Script        = 'TelemetryComponents.ps1'
    States        = @(
        @{
            Name             = 'Run'
            Launcher         = '9. Troubleshooting\Telemetry Components.cmd'
            ToolboxLauncher  = 'Scripts\Troubleshooting\Telemetry Components.cmd'
            Reboot           = 'Prompt'
            MachineAction    = 'Invoke-AtlasTelemetryComponentsMenu'
            InteractiveState = 'Select-AtlasTelemetryComponentsState'
        }
        @{
            Name          = 'Add'
            Internal      = $true
            NoStateRecord = $true
            MachineAction = 'Add-AtlasTelemetryPackageToggle'
        }
        @{
            Name          = 'Remove'
            Internal      = $true
            NoStateRecord = $true
            MachineAction = 'Remove-AtlasTelemetryPackageToggle'
        }
    )
}
