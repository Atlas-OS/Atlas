@{
    Name        = 'Hide Recent Items'
    Description = 'Stops Windows keeping and showing recent files and frequent folders in Quick Access, Start and jump lists, and clears recent documents when you sign out.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowFrequent'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowRecent'; Type = 'DWord'; Data = 0 }
        # Disable recent items and frequent places in File Explorer
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_TrackDocs'; Type = 'DWord'; Data = 0 }
        # Clear history of recently opened documents on exit
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'ClearRecentDocsOnExit'; Type = 'DWord'; Data = 1 }
        # Do not keep history of recently opened documents
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoRecentDocsHistory'; Type = 'DWord'; Data = 1 }
        # Do not display or track items in jump lists from remote locations
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'NoRemoteDestinations'; Type = 'DWord'; Data = 1 }
    )
}
