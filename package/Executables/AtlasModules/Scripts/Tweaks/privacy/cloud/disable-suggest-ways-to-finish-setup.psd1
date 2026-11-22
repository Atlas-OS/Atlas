@{
    Name        = 'Disable Suggested Ways to Finish Setting Up Your Device'
    Description = 'Turns off the "Suggest ways to finish setting up my device" screen, which mostly promotes Microsoft cloud services.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement'; Name = 'ScoobeSystemSettingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
