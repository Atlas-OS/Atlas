@{
    Name        = 'Configure Taskbar Pins'
    Description  = 'Configures taskbar pins for QoL: the browser first (if any), then File Explorer.'
    OnUpgrade   = 'Skip'
    Registry    = @(
        # HKCU entries are redirected to the interactive user (and mirrored to the default
        # hive) by the engine.
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'; Operation = 'AddKey' }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'; Name = 'FavoritesVersion'; Type = 'DWord'; Data = 3 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins'; Name = 'MailPin'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins'; Name = 'CopilotPWAPin'; Type = 'DWord'; Data = 0 }
    )
    # The chosen browser and the oobe-only pin application need per-option logic that a
    # single Option gate cannot express.
    Script       = 'config-pins.ps1'
}
