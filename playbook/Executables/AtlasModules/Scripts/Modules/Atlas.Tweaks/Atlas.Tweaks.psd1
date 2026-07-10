@{
    RootModule        = 'Atlas.Tweaks.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '2b60d6d6-e806-4cf0-95ad-3f133cef973e'
    Author            = 'AtlasOS'
    Description       = 'Atlas tweak engine: loads declarative tweak .psd1 data files, evaluates Option/Arch/OnUpgrade/Oobe gates and applies Registry/Services/ScheduledTasks/Run/Script actions.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-AtlasTweakManifest'
        'Test-AtlasTweakManifest'
        'Test-AtlasTweakApplicable'
        'Invoke-AtlasTweak'
        'Invoke-AtlasTweakCategory'
        'Test-AtlasTweakSchema'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
