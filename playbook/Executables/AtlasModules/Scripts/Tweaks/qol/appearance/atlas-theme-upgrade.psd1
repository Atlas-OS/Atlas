@{
    Name        = 'Refresh Theme On Upgrade'
    Description  = 'On upgrades, keeps the Atlas theme as the default for new users. The
ThemeFile policy enforces the theme at the next logon without any interactive shell COM.'
    OnUpgrade   = 'Only'
    Registry    = @(
        # Set the Atlas theme as the default for new accounts (default-user hive, loaded
        # during install).
        @{ Path = 'HKU\Atlas_DefaultUser\Software\Policies\Microsoft\Windows\Personalization'; Name = 'ThemeFile'; Type = 'ExpandString'; Data = '%windir%\Resources\Themes\atlas-v0.5.x-dark.theme' }
    )
}
