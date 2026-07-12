@{
    RootModule        = 'Atlas.Services.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '7a1f4c92-6e3b-4d18-9c5a-2f8e0b7d4a61'
    Author            = 'AtlasOS'
    Description       = 'Atlas service and driver configuration: checked startup changes, service stopping, strict default-services backup validation, and typed restoration.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasServiceStartup'
        'Stop-AtlasService'
        'Restore-AtlasServicesBackup'
        'Export-AtlasServicesBackup'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
