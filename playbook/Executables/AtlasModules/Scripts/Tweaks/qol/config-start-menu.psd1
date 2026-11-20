@{
    Name          = 'Configure Start Menu'
    OnUpgrade     = 'Skip'
    Description    = 'Configures the Start menu pins and removes the Most used, Recently added and Recommended lists.'
    Registry      = @(
        # Windows 11 24H2+ StartMenu.admx uses an enable value plus an expandable
        # path to the exported JSON. applyOnce keeps the resulting layout user-editable.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ConfigureStartPins'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ConfigureStartPinsJSON'; Type = 'ExpandString'; Data = '%SystemRoot%\AtlasModules\Other\StartLayout.json' }
        # Remove the unsupported internal PolicyManager mirror of ConfigureStartPins.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start'; Name = 'ConfigureStartPins'; Operation = 'Delete'; IgnoreErrors = $true }
        # Hide the "Most used" list from the Start Menu.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ShowOrHideMostUsedApps'; Type = 'DWord'; Data = 2 }
        # Remove the "Recently added" list from the Start Menu.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps'; Type = 'DWord'; Data = 1 }
        # Remove personalised website recommendations from the Recommended section.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedPersonalizedSites'; Type = 'DWord'; Data = 1 }
        # Remove the entire Recommended section from the Start Menu. Pro, Enterprise,
        # Education and IoT Enterprise honour this; Home doesn't.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection'; Type = 'DWord'; Data = 1 }
    )
    # The companion runs the Start Menu cache and process work as the install user.
    Script         = 'config-start-menu.ps1'
}
