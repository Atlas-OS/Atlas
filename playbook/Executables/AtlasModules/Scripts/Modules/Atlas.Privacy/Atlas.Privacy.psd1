@{
    RootModule        = 'Atlas.Privacy.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a5d7c2e9-3f81-4b6d-8e4a-7c9b2d1f5e68'
    Author            = 'AtlasOS'
    Description       = 'Atlas privacy configuration: the Location machine state (services, Find My Device policy, settings pages), DiagTrack log cleanup during install, and the NoTelemetry package menu.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasLocationMachineState'
        'Clear-AtlasTelemetryLogFiles'
        'Remove-AtlasTelemetryComponents'
        'Read-AtlasTelemetryPackageChoice'
        'Set-AtlasTelemetryPackageState'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
