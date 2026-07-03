@{
    RootModule        = 'Atlas.Themes.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c4e18b7a-2f96-4d31-8b5c-1e7a9d0f3c62'
    Author            = 'AtlasOS'
    Description       = 'Theme and lock-screen application (COM IThemeManager with an explorer fallback).'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasTheme'
        'Set-AtlasThemeMru'
        'Set-AtlasLockscreenImage'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
