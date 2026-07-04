@{
    Name        = 'Add Theme'
    Description  = 'Lock-screen policy for fresh installs. The dark theme and lock-screen
image need shell COM in a real user session, so Initialize-NewUser applies them: during
the install for the installing account (-FromInstall), at first logon for new accounts.'
    OnUpgrade   = 'Skip'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'LockScreenOverlaysDisabled'; Type = 'DWord'; Data = 1 }
        # RotatingLockScreenEnabled moved to disable-windows-spotlight, which runs on
        # upgrades too (this tweak is fresh-install only).
    )
    Script      = 'atlas-theme.ps1'
}
