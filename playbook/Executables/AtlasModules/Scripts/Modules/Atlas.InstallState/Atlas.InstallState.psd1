@{
    RootModule        = 'Atlas.InstallState.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'f2e6d327-ce7f-4692-a1f6-64bf95d25088'
    Author            = 'AtlasOS'
    Description       = 'Compact durable state for an Atlas installation run.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-AtlasInstallStatePath'
        'Get-AtlasInstallState'
        'Get-AtlasInstallWorkRoot'
        'Start-AtlasInstallState'
        'Add-AtlasInstallOption'
        'Set-AtlasInstallUser'
        'Commit-AtlasInstallState'
        'Invoke-AtlasInstallStep'
        'Complete-AtlasInstallState'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
