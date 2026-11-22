@{
    Name        = 'Disable Windows Spotlight'
    Description = 'Turns off Windows Spotlight on the lock screen and desktop, including its tips and "Like what you see?" prompts.'
    Registry    = @(
        # Only Enterprise and Education enforce the CloudContent spotlight policies, so
        # they're an extra layer there; the ContentDeliveryManager values below are
        # what disables Spotlight on all editions.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightFeatures'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightWindowsWelcomeExperience'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightOnActionCenter'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightOnSettings'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableThirdPartySuggestions'; Type = 'DWord'; Data = 1 }
        # Spotlight lock screen, lock-screen fun facts/tips and desktop spotlight.
        # Applied here, on every install, rather than in atlas-theme, which skips updates.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'RotatingLockScreenOverlayEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338387Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353694Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353696Enabled'; Type = 'DWord'; Data = 0 }
        # Hide the Spotlight 'Learn about this picture' desktop icon.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'; Name = '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}'; Type = 'DWord'; Data = 1 }
    )
}
