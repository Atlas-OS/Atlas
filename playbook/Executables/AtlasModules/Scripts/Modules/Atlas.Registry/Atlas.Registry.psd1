@{
    RootModule        = 'Atlas.Registry.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '543dae25-b8af-44b3-8a92-a151695f97f0'
    Author            = 'AtlasOS'
    Description       = 'Atlas registry engine: token-bound HKCU operations, fixed default-user targeting and declarative registry entry application.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        # Path resolution and explicit identity binding
        'Resolve-AtlasRegistryPath'
        'Initialize-AtlasRegistryIdentityContext'
        # Values and keys
        'Set-AtlasRegistryValue'
        'Remove-AtlasRegistryValue'
        'New-AtlasRegistryKey'
        'Remove-AtlasRegistryKey'
        # .reg import and declarative entries
        'Import-AtlasRegFile'
        'Invoke-AtlasRegistryEntries'
        # Known-folder helpers (former UserPaths module)
        'Get-UserPath'
        'Get-SystemDrive'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
