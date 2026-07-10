@{
    RootModule        = 'Atlas.Registry.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '543dae25-b8af-44b3-8a92-a151695f97f0'
    Author            = 'AtlasOS'
    Description       = 'Atlas registry engine: HKCU redirection under TrustedInstaller, default-user-hive mirroring, user hive enumeration and declarative registry entry application.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        # Path resolution and user hives
        'Resolve-AtlasRegistryPath'
        'Get-AtlasActiveUserSid'
        'Get-AtlasUserHives'
        'Get-RegUserPaths'            # compatibility export (former AllRegistryUsers module)
        # Values and keys
        'Set-AtlasRegistryValue'
        'Remove-AtlasRegistryValue'
        'New-AtlasRegistryKey'
        'Remove-AtlasRegistryKey'
        # .reg import, default-hive sync and declarative entries
        'Import-AtlasRegFile'
        'Complete-AtlasHkcuDeltaJournal'
        'Sync-AtlasDefaultUserHive'
        'Invoke-AtlasRegistryEntries'
        # Known-folder helpers (former UserPaths module)
        'Get-UserPath'
        'Get-SystemDrive'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
