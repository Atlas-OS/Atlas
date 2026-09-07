@{
    RootModule        = 'Atlas.Shell.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c4e7a2d9-5b16-4f83-a9d0-6e1c8b3f7a52'
    Author            = 'AtlasOS'
    Description       = 'Atlas shell configuration: Settings page visibility, current-user file associations, Send To context-menu items, shell context-menu handler helpers, Start layout, taskbar pins and File Explorer Home pins.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasSettingsPageVisibility'
        'Set-AtlasFileAssociations'
        'Set-AtlasSendToContextMenu'
        'ConvertTo-AtlasShellWindowsArgument'
        'Get-AtlasTakeOwnershipArgumentPlan'
        'Assert-AtlasTakeOwnershipTree'
        'Set-AtlasStartLayout'
        'Set-AtlasTaskbarPins'
        'Add-AtlasMusicVideosToHome'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
