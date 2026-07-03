@{
    Name        = 'Disable Sync Provider Notifications'
    Description = 'Disables notifications within File Explorer from OneDrive or other sync providers to avoid advertisements'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowSyncProviderNotifications'; Type = 'DWord'; Data = 0 }
    )
}
