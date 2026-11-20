@{
    Name        = 'Configure Windows Media Player'
    Description = 'Turns off the Windows Media Player first-run wizard and usage tracking, and stops Windows Media DRM going online.'
    Registry    = @(
        # Prevent Windows Media DRM internet access
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\WMDRM'; Name = 'DisableOnline'; Type = 'DWord'; Data = 1 }
        # Disable Windows Media Player wizard on first run
        @{ Path = 'HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences'; Name = 'AcceptedPrivacyStatement'; Type = 'DWord'; Data = 1 }
        # Disable Windows Media Player diagnostics
        @{ Path = 'HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences'; Name = 'UsageTracking'; Type = 'DWord'; Data = 0 }
    )
}
