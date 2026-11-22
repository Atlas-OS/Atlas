@{
    Name        = 'Disable Sync Provider Notifications'
    Description = 'Stops OneDrive and other sync providers showing notifications, often adverts, in File Explorer.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowSyncProviderNotifications'; Type = 'DWord'; Data = 0 }
    )
}
