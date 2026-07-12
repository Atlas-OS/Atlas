@{
    RootModule        = 'AtlasBuild.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'e1b1a9c2-42f3-4c1d-9a06-7c2f8b7f7a10'
    Author            = 'AtlasOS'
    Description       = 'Build tooling for the Atlas playbook (.apbx packaging and dev-build staging).'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Resolve-SevenZip'
        'Invoke-SevenZip'
        'Get-PlaybookVersion'
        'Get-AvailableArchiveName'
        'Get-AtlasPlaybookPayloadPath'
        'Compare-AtlasPayloadPath'
        'Get-AtlasYamlAction'
        'Get-AtlasConfigurationRunnerContract'
        'Assert-AtlasConfigurationRunnerBoundary'
        'New-StagedPlaybookConf'
        'Set-OemVersionStamp'
        'New-Apbx'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
