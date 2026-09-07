@{
    RootModule        = 'Atlas.Security.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '3e7a9c14-5b2d-4f86-a1c7-8d0e6b4f2a93'
    Author            = 'AtlasOS'
    Description       = 'Atlas security configuration: Windows Defender package state, documented Virtualization-Based Security and memory-integrity configuration, and the Windows TEMP permission repair.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-AtlasDefenderState'
        'Set-AtlasDefenderState'
        'Read-AtlasDefenderStateChoice'
        'Get-AtlasVbsConfiguration'
        'Set-AtlasVbsConfiguration'
        'Repair-AtlasWindowsTempPermissions'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
