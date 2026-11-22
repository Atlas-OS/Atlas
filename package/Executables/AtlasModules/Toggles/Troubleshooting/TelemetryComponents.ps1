# Companion for the TelemetryComponents toggle: adds or removes the Atlas NoTelemetry package.
# Select-AtlasTelemetryComponentsState runs first, in the administrator window: it shows the
# menu and picks an internal state. That state's function then runs in the silent
# TrustedInstaller broker. Nothing is recorded.

function Select-AtlasTelemetryComponentsState {
    param($Toggle)

    if ($Toggle.Silent) {
        throw 'Choosing whether to add or remove the NoTelemetry package needs an interactive window.'
    }
    Import-AtlasModule -Name Atlas.Privacy
    return Read-AtlasTelemetryPackageChoice
}

function Invoke-AtlasTelemetryComponentsMenu {
    param($Toggle)

    # Reached only by a direct silent request for the public state, which has no
    # choice to apply; the interactive path never runs this action.
    [void]$Toggle
    throw 'Telemetry Components needs an interactive window to choose between adding and removing the NoTelemetry package.'
}

function Add-AtlasTelemetryPackageToggle {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Privacy
    Set-AtlasTelemetryPackageState -State Installed -Silent:$Toggle.Silent
}

function Remove-AtlasTelemetryPackageToggle {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Privacy
    Set-AtlasTelemetryPackageState -State Removed -Silent:$Toggle.Silent
}
