@{
    Name        = 'Add Theme'
    Description  = 'Sets the lock screen policy on fresh installs. The dark theme and lock screen image need a real user session, so Initialize-NewUser applies them: for the install user during the install, and for each new account at its first sign-in.'
    OnUpgrade   = 'Skip'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'LockScreenOverlaysDisabled'; Type = 'DWord'; Data = 1 }
        # disable-windows-spotlight sets RotatingLockScreenEnabled, because it also runs on
        # updates; this tweak runs on fresh installs only.
    )
    Script      = 'atlas-theme.ps1'
}
