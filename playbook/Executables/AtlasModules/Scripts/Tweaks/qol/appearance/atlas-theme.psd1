@{
    Name        = 'Add Theme'
    Description  = 'Applies the Atlas dark theme and lock-screen on fresh installs.'
    # Fresh installs only; the upgrade path (re-apply theme MRU + default-user theme file)
    # is atlas-theme-upgrade.psd1.
    OnUpgrade   = 'Skip'
    # Applying a theme (IThemeManager) and the lock-screen image are COM calls against the
    # running shell, so the companion runs in the interactive user's elevated session.
    RunAs       = 'UserElevated'
    Registry    = @(
        # Reliable policy writes stay in the engine (run as TrustedInstaller) so they apply
        # even if the user-session theme apply below cannot run.
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'LockScreenOverlaysDisabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenEnabled'; Type = 'DWord'; Data = 0 }
    )
    Script      = 'atlas-theme.ps1'
}
