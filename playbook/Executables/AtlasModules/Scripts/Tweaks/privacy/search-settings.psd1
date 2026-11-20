@{
    Name        = 'Configure Search on the Taskbar'
    Description = 'Turns off web and cloud results, search history, location use and search highlights in Windows Search, and shows search as an icon on the taskbar.'
    Registry    = @(
        # Windows may refuse these preferences; the machine policy still blocks cloud search.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsAADCloudSearchEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDeviceSearchHistoryEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsMSACloudSearchEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
        # Policies
        # Search.admx / https://learn.microsoft.com/windows/client-management/mdm/policy-csp-search#allowcloudsearch
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCloudSearch'; Type = 'DWord'; Data = 0 }
        # Only Enterprise and Education honour ConnectedSearchUseWeb, so it's an extra layer there;
        # DisableSearchBoxSuggestions below is what disables web search on all editions.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'ConnectedSearchUseWeb'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowSearchToUseLocation'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'EnableDynamicContentInWSB'; Type = 'DWord'; Data = 0 }
        # Disable online search and don't include web results from Bing
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Type = 'DWord'; Data = 1 }
        # Set search as icon on taskbar. Windows can protect this key too; the search
        # box then stays as it was, and the policies above still apply.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarModeCache'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
    )
}
