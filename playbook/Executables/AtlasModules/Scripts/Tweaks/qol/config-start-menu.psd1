@{
    Name          = 'Configure Start Menu'
    Description    = 'Configures the Start Menu pins and removes the frequent, recently-added and recommended lists.'
    Registry      = @(
        # Configure the default Windows 11 pins.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start'; Name = 'ConfigureStartPins'; Type = 'String'; Data = '{"pinnedList":[{"packagedAppId":"windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel"},{"packagedAppId":"Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"},{"desktopAppLink":"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\File Explorer.lnk"},{"packagedAppId":"Microsoft.WindowsStore_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.GamingApp_8wekyb3d8bbwe!Microsoft.Xbox.App"},{"packagedAppId":"Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.WindowsNotepad_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.Paint_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.SecHealthUI_8wekyb3d8bbwe!SecHealthUI"}]}' }
        # Hide the "Most used" list from the Start Menu.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ShowOrHideMostUsedApps'; Type = 'DWord'; Data = 2 }
        # Remove the "Recently added" list from the Start Menu.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps'; Type = 'DWord'; Data = 1 }
        # Remove personalized website recommendations from the Recommended section.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedPersonalizedSites'; Type = 'DWord'; Data = 1 }
        # Remove the entire Recommended section from the Start Menu. Windows 11 22H2+,
        # Pro/Enterprise/Education/IoT Enterprise - not honored on Home.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection'; Type = 'DWord'; Data = 1 }
    )
    # The companion routes Start Menu cache/process work through the exact install-state user.
    Script         = 'config-start-menu.ps1'
}
