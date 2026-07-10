@{
    RootModule        = 'Atlas.Toggles.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '5e8d2b7a-1c94-4a6e-8f3b-9d0c4e7a2b51'
    Author            = 'AtlasOS'
    Description       = 'Atlas toggle engine: loads per-toggle definitions, records user setting state, handles elevation and re-applies recorded toggles on upgrades.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        # Engine
        'Get-AtlasToggleDefinition'
        'Invoke-AtlasToggle'
        # State registry (HKLM\SOFTWARE\AtlasOS\Services compatibility contract)
        'Get-AtlasToggleState'
        'Set-AtlasToggleState'
        # Interaction
        'Show-AtlasStateMenu'
        # State-store initialization and upgrade re-apply
        'Initialize-AtlasToggleStateStore'
        'Invoke-AtlasToggleReapply'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
