@{
    RootModule        = 'Atlas.Registry.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '543dae25-b8af-44b3-8a92-a151695f97f0'
    Author            = 'AtlasOS'
    Description       = 'Atlas registry engine: token-bound HKCU operations, install-bound protected user policies, fixed default-user targeting and declarative registry entry application.'
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
        # Entry gates shared with the tweak engine and its schema validation
        'Test-AtlasArchMatch'
        'Get-AtlasRegistryEntryTargetScope'
        # Known-folder helper
        'Get-UserPath'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
