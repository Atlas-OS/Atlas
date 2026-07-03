@{
    Name        = 'Disable Automatic Updates for Apps in Store'
    Description = 'Disables automatic updates for apps in Store so that the user has more control'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'; Name = 'AutoDownload'; Type = 'DWord'; Data = 2 }
    )
}
