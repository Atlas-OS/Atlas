@{
    Name        = 'Configure Windows Media Player'
    Description = 'Configures Windows Media Player for the optimal privacy, security and usability. As a note, WMP is old, and you probably shouldn''t use it.'
    Registry    = @(
        # Prevent Windows Media DRM internet access
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\WMDRM'; Name = 'DisableOnline'; Type = 'DWord'; Data = 1 }
        # Disable Windows Media Player wizard on first run
        @{ Path = 'HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences'; Name = 'AcceptedPrivacyStatement'; Type = 'DWord'; Data = 1 }
        # Disable Windows Media Player diagnostics
        @{ Path = 'HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences'; Name = 'UsageTracking'; Type = 'DWord'; Data = 0 }
    )
}
