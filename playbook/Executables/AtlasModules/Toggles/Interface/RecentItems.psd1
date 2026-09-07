@{
    Name        = 'RecentItems'
    Description = 'Recent Items and app or document usage tracking. Enable removes restrictions so users can configure tracking; it preserves their tracking preferences rather than turning them on. Disable turns tracking off. Both states also hide or unhide the general privacy settings page and refresh Explorer and Settings.'
    Elevation   = 'Admin'
    Script      = 'RecentItems.ps1'
    States      = @(
        @{
            Name                  = 'Disable'
            StateValue            = 0
            Launcher              = '4. Interface Tweaks\Unlock Recent Items\Disable Recent Items (default).cmd'
            Reboot                = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerAndSettingsRefresh'
            Registry              = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoStartMenuMFUprogramsList'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoInstrumentation'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'ClearRecentDocsOnExit'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoRecentDocsHistory'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ShowOrHideMostUsedApps'; Type = 'DWord'; Data = 2 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'NoRemoteDestinations'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackProgs'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackDocs'; Type = 'DWord'; Data = 0 }
            )
            MachineAction         = 'Set-AtlasRecentItemsSettingsPage'
            UserAction            = 'Show-AtlasRecentItemsMessage'
        }
        @{
            Name                  = 'Enable'
            StateValue            = 1
            Launcher              = '4. Interface Tweaks\Unlock Recent Items\Unlock Recent Items.cmd'
            Reboot                = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerAndSettingsRefresh'
            Registry              = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoStartMenuMFUprogramsList'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoInstrumentation'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'ClearRecentDocsOnExit'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoRecentDocsHistory'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'ShowOrHideMostUsedApps'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecentlyAddedApps'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'NoRemoteDestinations'; Operation = 'Delete' }
            )
            MachineAction         = 'Set-AtlasRecentItemsSettingsPage'
            UserAction            = 'Show-AtlasRecentItemsMessage'
        }
    )
}
