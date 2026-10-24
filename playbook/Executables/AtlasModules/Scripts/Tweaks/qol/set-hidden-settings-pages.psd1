@{
    Name        = 'Set Hidden Pages'
    Description = 'Hides Settings pages that are broken or unused.'
    # Fresh installs only; the install plan runs it as its own
    # 'Tweak/qol/set-hidden-settings-pages' step before the Tweaks/<category> steps, so
    # later tweaks do not overwrite SettingsPageVisibility.
    OnUpgrade   = 'Skip'
    Script      = 'set-hidden-settings-pages.ps1'
}
