@{
    Name        = 'Disable Windows Spotlight'
    Description = 'Windows Spotlight provides lockscreen messages like ''Like what you see?'', and are disabled for QoL and privacy'
    Registry    = @(
        # CloudContent spotlight policies are only enforced on Enterprise/Education -
        # kept as an extra layer there; the ContentDeliveryManager values below are
        # what disables Spotlight on all editions.
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightFeatures'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightWindowsWelcomeExperience'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightOnActionCenter'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightOnSettings'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableThirdPartySuggestions'; Type = 'DWord'; Data = 1 }
        # Spotlight lock screen, lock-screen fun facts/tips and desktop spotlight.
        # Applied here (all installs) rather than in atlas-theme, which skips upgrades.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenOverlayEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338387Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353694Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353696Enabled'; Type = 'DWord'; Data = 0 }
        # Hide the Spotlight 'Learn about this picture' desktop icon.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'; Name = '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}'; Type = 'DWord'; Data = 1 }
    )
}
