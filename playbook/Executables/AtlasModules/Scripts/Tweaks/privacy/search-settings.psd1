@{
    Name        = 'Configure Search on the Taskbar'
    Description = 'Configures search for the optimal usability and privacy, such as disabling online features to make it more minimal and snappy'
    Registry    = @(
        # Configure search permissions
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsAADCloudSearchEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDeviceSearchHistoryEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsMSACloudSearchEnabled'; Type = 'DWord'; Data = 0 }
        # Policies
        # ConnectedSearchUseWeb is only honored on Enterprise/Education - kept as an extra layer there;
        # DisableSearchBoxSuggestions below is what disables web search on all editions.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'ConnectedSearchUseWeb'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowSearchToUseLocation'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'EnableDynamicContentInWSB'; Type = 'DWord'; Data = 0 }
        # Disable online search and don't include web results from Bing
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Type = 'DWord'; Data = 1 }
        # Set search as icon on taskbar
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarModeCache'; Type = 'DWord'; Data = 1 }
    )
}
