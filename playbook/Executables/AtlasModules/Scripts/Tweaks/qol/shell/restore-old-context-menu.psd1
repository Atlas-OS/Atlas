@{
    Name        = 'Restore Old Context Menu'
    Description = 'Restores the old context menu in Windows 11'
    MinBuild    = 22000
    # The registry write happens in the companion script because the required default
    # ('') value cannot be expressed in the Registry schema.
    Script      = 'restore-old-context-menu.ps1'
}
