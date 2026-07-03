@{
    Name        = 'Add Theme'
    Description  = 'Lock-screen policy for fresh installs. The dark theme and lock-screen
image are applied by Initialize-NewUser at first logon, where the shell COM runs in the
real user session; applying them here (from the SYSTEM install phase) restarts the shell
and tears down the phase.'
    OnUpgrade   = 'Skip'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'LockScreenOverlaysDisabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenEnabled'; Type = 'DWord'; Data = 0 }
    )
    Script      = 'atlas-theme.ps1'
}
