@{
    RootModule        = 'AtlasBuild.psm1'
    ModuleVersion     = '2.0.0'
    GUID              = 'e1b1a9c2-42f3-4c1d-9a06-7c2f8b7f7a10'
    Author            = 'AtlasOS'
    Description       = 'Build tooling for the Atlas package (.atlaspkg packaging, manifest checks and test-build staging).'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Resolve-SevenZip'
        'Invoke-SevenZip'
        'Get-AtlasPackagePassword'
        'Get-AtlasPackageVersion'
        'Test-AtlasManifest'
        'ConvertTo-AtlasManifestJson'
        'Get-AvailableArchiveName'
        'Get-AtlasPackageFilePath'
        'Compare-AtlasPackageFilePath'
        'New-StagedAtlasManifest'
        'Set-OemVersionStamp'
        'New-AtlasPackage'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
