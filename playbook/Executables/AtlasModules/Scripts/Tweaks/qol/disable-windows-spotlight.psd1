@{
    Name        = 'Disable Windows Spotlight'
    Description = 'Windows Spotlight provides lockscreen messages like ''Like what you see?'', and are disabled for QoL and privacy'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightFeatures'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightWindowsWelcomeExperience'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightOnActionCenter'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightOnSettings'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableThirdPartySuggestions'; Type = 'DWord'; Data = 1 }
        # 'NewStartPanelt' is preserved verbatim from the legacy playbook.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanelt'; Name = '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}'; Type = 'DWord'; Data = 1 }
    )
}
