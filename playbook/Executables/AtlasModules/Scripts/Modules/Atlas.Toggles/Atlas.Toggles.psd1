@{
    RootModule        = 'Atlas.Toggles.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '5e8d2b7a-1c94-4a6e-8f3b-9d0c4e7a2b51'
    Author            = 'AtlasOS'
    Description       = 'Atlas toggle engine: loads data-only toggle definitions, runs their machine and user work in the right context, records user setting state, and replays recorded toggles on upgrades and first sign-in.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        # Definitions
        'Get-AtlasToggleDefinition'
        'Test-AtlasToggleDefinition'
        'Get-AtlasToggleStateWork'
        # Engine
        'Invoke-AtlasToggle'
        # Machine work of one state, invoked from other privileged callers
        'Invoke-AtlasToggleMachineState'
        # State registry (HKLM\SOFTWARE\AtlasOS\Services compatibility contract)
        'Get-AtlasToggleState'
        'Get-AtlasToggleStateRecords'
        'Set-AtlasToggleState'
        # Checked native command invocation for companion functions
        'Invoke-AtlasToggleNativeCommand'
        # State-store initialization and replay
        'Initialize-AtlasToggleStateStore'
        'Invoke-AtlasToggleReapply'
        'Invoke-AtlasToggleUserReapply'
        # Verification of recorded states against the machine
        'Test-AtlasToggleState'
        'Test-AtlasToggleDrift'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
