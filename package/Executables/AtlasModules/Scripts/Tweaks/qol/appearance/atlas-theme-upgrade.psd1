@{
    Name        = 'Refresh Theme On Upgrade'
    Description  = 'Keeps the Atlas theme as the default for new accounts when Atlas updates. The ThemeFile policy applies it at the next sign-in, without needing the user''s session during the install.'
    OnUpgrade   = 'Only'
    Registry    = @(
        # Set the Atlas theme as the default for new accounts (default-user hive, loaded
        # during install).
        @{ Path = 'HKU\Atlas_DefaultUser\Software\Policies\Microsoft\Windows\Personalization'; Name = 'ThemeFile'; Type = 'ExpandString'; Data = '%windir%\Resources\Themes\atlas-v0.5.x-dark.theme' }
    )
}
