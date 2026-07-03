@{
    RootModule        = 'Atlas.Core.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '0b7c9f3e-8a41-4f7e-b6a2-3d5c1e9f2a84'
    Author            = 'AtlasOS'
    Description       = 'Core Atlas framework: install context, option flags, logging, privilege checks and shared UI helpers.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        # Context
        'Get-AtlasContext'
        'Test-AtlasOption'
        'New-AtlasFlag'
        'Test-AtlasFlag'
        # Logging
        'Write-AtlasLog'
        'Start-AtlasPhase'
        'Stop-AtlasPhase'
        # Privilege
        'Test-AtlasAdmin'
        'Test-AtlasTrustedInstaller'
        'Assert-AtlasPrivilege'
        'Invoke-AtlasTrustedInstaller'
        # UI (absorbed from the former Utils module)
        'Write-Title'
        'Read-Pause'
        'Read-MessageBox'
        # Process/task helpers (absorbed from the former Utils module)
        'Stop-ProcessesUnderRoots'
        'Stop-TasksUnderRoots'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
