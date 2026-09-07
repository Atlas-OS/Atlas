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
