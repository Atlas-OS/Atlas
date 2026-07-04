@{
    Name        = 'Set Hidden Pages'
    Description  = 'Hides Settings pages that are broken or unused.'
    # Fresh installs only; invoked early from custom.yml (before the tweak categories) so
    # later tweaks do not overwrite SettingsPageVisibility.
    OnUpgrade   = 'Skip'
    Script      = 'set-hidden-settings-pages.ps1'
}
