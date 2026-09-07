@{
    RootModule        = 'Atlas.State.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '8c1f6d2e-4b7a-4e39-9d5c-1a2f3b4c5d6e'
    Author            = 'AtlasOS'
    Description       = 'The Atlas machine state document: installed version, install history, selected options and the recorded AtlasDesktop toggle states.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-AtlasStatePath'
        'Get-AtlasState'
        'Update-AtlasState'
        'Set-AtlasStateInstall'
        'Set-AtlasStateToggle'
        'Sync-AtlasStateToggles'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
