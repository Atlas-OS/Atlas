# Companion for the ConfigVBS toggle: shows the current Virtualisation-Based Security
# configuration. Show-AtlasVbsConfiguration runs in the launcher's own process, as you, when
# you run the launcher; nothing is recorded.

function Show-AtlasVbsConfiguration {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Security
    $report = Get-AtlasVbsConfiguration
    Write-AtlasNote -Text @(
        "VBS status: $($report.VbsStatus)"
        "Configured services: $($report.ConfiguredServices -join ', ')"
        "Running services: $($report.RunningServices -join ', ')"
        "Required security properties: $($report.RequiredProperties -join ', ')"
        "Available security properties: $($report.AvailableProperties -join ', ')"
    )
    [void]$Toggle
}
