@{
    Name        = 'Configure Taskbar Pins'
    Description  = 'Configures taskbar pins for QoL: the browser first (if any), then File Explorer.'
    OnUpgrade   = 'Skip'
    Registry    = @(
        # The engine applies HKCU in separate exact-user and fixed default-hive passes; it
        # never redirects TrustedInstaller through a discovered live-user hive.
        # Explorer can transiently deny writes to its live Taskband key. These values
        # are advisory seeds: Initialize-NewUser performs and verifies the authoritative
        # pin replacement later, so contention here must not halt the installation.
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'; Operation = 'AddKey'; IgnoreErrors = $true }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'; Name = 'FavoritesVersion'; Type = 'DWord'; Data = 3; IgnoreErrors = $true }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins'; Name = 'MailPin'; Type = 'DWord'; Data = 0; IgnoreErrors = $true }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins'; Name = 'CopilotPWAPin'; Type = 'DWord'; Data = 0; IgnoreErrors = $true }
    )
    # The chosen browser and the oobe-only pin application need per-option logic that a
    # single Option gate cannot express.
    Script       = 'config-pins.ps1'
}
