@{
    Name        = 'WebSearch'
    # Enable offers indexing because Windows Search draws incorrectly without it. Both states refresh
    # Explorer and SearchHost unless the launcher runs with /noAction.
    Description = 'Turns web search and search highlights on or off. Enable installs the Bing search provider through WinGet and, when search indexing is off, offers to turn it on.'
    Elevation   = 'Admin'
    Script      = 'WebSearch.ps1'
    States      = @(
        @{
            Name                  = 'Disable'
            StateValue            = 0
            Launcher              = '3. General Configuration\Web Search (includes Search Highlights)\Disable Web Search (default).cmd'
            Reboot                = 'RestartExplorer'
            ShellRefreshOperation = 'SearchShellRefresh'
            Registry              = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCloudSearch'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowSearchToUseLocation'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'ConnectedSearchUseWeb'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'DisableWebSearch'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'EnableDynamicContentInWSB'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsAADCloudSearchEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDeviceSearchHistoryEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsMSACloudSearchEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'SafeSearchMode'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDynamicSearchBoxEnabled'; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
            )
            MachineAction         = 'Disable-AtlasWebSearchMachine'
        }
        @{
            Name                  = 'Enable'
            StateValue            = 1
            Launcher              = '3. General Configuration\Web Search (includes Search Highlights)\Enable Web Search.cmd'
            Reboot                = 'RestartExplorer'
            ShellRefreshOperation = 'SearchShellRefresh'
            Registry              = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCloudSearch'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'ConnectedSearchUseWeb'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'DisableWebSearch'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'EnableDynamicContentInWSB'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Operation = 'Delete' }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Operation = 'Delete'; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsAADCloudSearchEnabled'; Operation = 'Delete'; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDeviceSearchHistoryEnabled'; Operation = 'Delete'; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsMSACloudSearchEnabled'; Operation = 'Delete'; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'SafeSearchMode'; Operation = 'Delete'; AllowOsProtected = $true }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDynamicSearchBoxEnabled'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Data = 2; AllowOsProtected = $true }
            )
            MachineAction         = 'Enable-AtlasWebSearchMachine'
            UserAction            = 'Enable-AtlasWebSearchUser'
        }
    )
}
