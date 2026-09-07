@{
    RootModule        = 'Atlas.Download.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '5d2f8a1c-7b3e-4c9a-9f61-2e8b4d0c7a15'
    Author            = 'AtlasOS'
    Description       = 'Bounded HTTPS downloads, protected staging, contained native execution, GitHub release resolution and trusted WinGet resolution.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'New-AtlasProtectedStagingDirectory'
        'Test-AtlasProtectedStagingAcl'
        'Invoke-AtlasBoundedHttpGet'
        'Invoke-AtlasPinnedDownload'
        'Test-AtlasProtectedExecutionAcl'
        'Resolve-AtlasProtectedExecutionPath'
        'Invoke-AtlasContainedProcess'
        'Test-AtlasContainedProcessContainmentUnconfirmed'
        'Invoke-AtlasGitHubApiJson'
        'Get-AtlasLatestGitHubReleaseAsset'
        'Get-AtlasTrustedWingetPath'
        'Assert-AtlasTrustedWingetSource'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
