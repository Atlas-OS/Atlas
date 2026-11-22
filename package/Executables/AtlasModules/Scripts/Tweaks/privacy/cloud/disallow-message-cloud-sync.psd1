@{
    Name        = 'Disallow Message Service Cloud Sync'
    Description = 'Stops Windows backing up text messages to the cloud.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging'; Name = 'AllowMessageSync'; Type = 'DWord'; Data = 0 }
    )
}
