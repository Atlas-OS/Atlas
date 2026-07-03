@{
    RootModule        = 'Atlas.Services.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '7a1f4c92-6e3b-4d18-9c5a-2f8e0b7d4a61'
    Author            = 'AtlasOS'
    Description       = 'Atlas service and driver configuration: startup type changes written directly to the registry (works for drivers and protected services under TrustedInstaller), service stopping and the default-services backup.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasServiceStartup'
        'Stop-AtlasService'
        'Export-AtlasServicesBackup'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
