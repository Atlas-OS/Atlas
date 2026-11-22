@{
    RootModule        = 'Atlas.Search.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'e8b4d5f2-7c31-4a9e-b0d6-5f2a8c1e7b34'
    Author            = 'AtlasOS'
    Description       = 'Atlas Windows Search configuration: checked index path, policy and WSearch service operations, the Disable/Minimal/Full indexing machine states, and the per-user Store search recommendation block.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasIndexConfiguration'
        'Set-AtlasIndexingMachineState'
        'Get-AtlasIndexScopeState'
        'Disable-AtlasStoreSearchRecommendations'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
