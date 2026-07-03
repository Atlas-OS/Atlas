@{
    Name        = 'Disable Suggested Ways to Finish Setting Up Your Device'
    Description = 'Disables suggested ways to finish setting up your device, as it will mostly anony you to use cloud features'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement'; Name = 'ScoobeSystemSettingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
