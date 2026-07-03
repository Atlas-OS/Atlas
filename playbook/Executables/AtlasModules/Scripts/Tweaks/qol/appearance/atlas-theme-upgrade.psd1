@{
    Name        = 'Refresh Theme On Upgrade'
    Description  = 'On upgrades, refreshes the theme MRU and keeps the Atlas theme as the default for new users.'
    OnUpgrade   = 'Only'
    RunAs       = 'UserElevated'
    Registry    = @(
        # Set the Atlas theme as the default for new accounts (default-user hive, loaded
        # during install).
        @{ Path = 'HKU\AME_UserHive_Default\Software\Policies\Microsoft\Windows\Personalization'; Name = 'ThemeFile'; Type = 'ExpandString'; Data = '%windir%\Resources\Themes\atlas-v0.5.x-dark.theme' }
    )
    Script      = 'atlas-theme-upgrade.ps1'
}
