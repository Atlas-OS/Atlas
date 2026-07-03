@{
    Name        = 'Open File Explorer to This PC'
    Description = 'Configures File Explorer to open to This PC instead of Quick Access for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'LaunchTo'; Type = 'DWord'; Data = 1 }
    )
}
