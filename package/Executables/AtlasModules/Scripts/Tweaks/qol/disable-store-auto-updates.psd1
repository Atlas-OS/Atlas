@{
    Name        = 'Disable Automatic Updates for Apps in Store'
    Description = 'Stops Microsoft Store updating apps automatically, so you choose when apps update.'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'; Name = 'AutoDownload'; Type = 'DWord'; Data = 2 }
    )
}
