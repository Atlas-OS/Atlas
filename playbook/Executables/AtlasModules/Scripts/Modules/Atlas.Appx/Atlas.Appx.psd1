@{
    RootModule        = 'Atlas.Appx.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '9b4e1d73-3c8a-42f5-a6d0-7e2b5c9f1a36'
    Author            = 'AtlasOS'
    Description       = 'Atlas AppX support: package snapshot/deprovisioning around the AME !appx removals, package cache clearing and Phone Link removal.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Save-AtlasAppxSnapshot'
        'Set-AtlasAppxDeprovisioned'
        'Clear-AtlasAppxCache'
        'Remove-AtlasPhoneLinkAppx'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
