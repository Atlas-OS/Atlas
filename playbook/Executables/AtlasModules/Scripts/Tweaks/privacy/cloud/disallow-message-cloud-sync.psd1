@{
    Name        = 'Disallow Message Service Cloud Sync'
    Description = 'Disallows the Message service (which should be disabled anyways) from syncing with the cloud, as that potentially harms privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging'; Name = 'AllowMessageSync'; Type = 'DWord'; Data = 0 }
    )
}
