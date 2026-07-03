@{
    Name        = 'Hide Recent Items'
    Description = 'Hide recent items in Quick Access and other places for privacy and QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowFrequent'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowRecent'; Type = 'DWord'; Data = 0 }
        # Disable recent items and frequent places in File Explorer
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackDocs'; Type = 'DWord'; Data = 0 }
        # Clear history of recently opened documents on exit
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'ClearRecentDocsOnExit'; Type = 'DWord'; Data = 1 }
        # Do not keep history of recently opened documents
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoRecentDocsHistory'; Type = 'DWord'; Data = 1 }
        # Do not display or track items in jump lists from remote locations
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'NoRemoteDestinations'; Type = 'DWord'; Data = 1 }
    )
}
