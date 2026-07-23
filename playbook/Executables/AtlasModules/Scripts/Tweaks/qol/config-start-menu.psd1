@{
    Name          = 'Configure Start Menu'
    Description    = 'Configures the Start Menu pins and removes the frequent, recently-added and recommended lists.'
    Registry      = @(
        # Windows 11 24H2+ StartMenu.admx uses an enable value plus an expandable
        # path to the exported JSON. applyOnce keeps the resulting layout user-editable.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ConfigureStartPins'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ConfigureStartPinsJSON'; Type = 'ExpandString'; Data = '%SystemRoot%\AtlasModules\Other\StartLayout.json' }
        # Remove the unsupported internal PolicyManager mirror used by the old tweak.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start'; Name = 'ConfigureStartPins'; Operation = 'Delete'; IgnoreErrors = $true }
        # Hide the "Most used" list from the Start Menu.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ShowOrHideMostUsedApps'; Type = 'DWord'; Data = 2 }
        # Remove the "Recently added" list from the Start Menu.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps'; Type = 'DWord'; Data = 1 }
        # Remove personalized website recommendations from the Recommended section.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedPersonalizedSites'; Type = 'DWord'; Data = 1 }
        # Remove the entire Recommended section from the Start Menu.
        # Pro/Enterprise/Education/IoT Enterprise - not honored on Home.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection'; Type = 'DWord'; Data = 1 }
    )
    # The companion routes Start Menu cache/process work through the exact install-state user.
    Script         = 'config-start-menu.ps1'
}
