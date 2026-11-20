@{
    Name        = 'Disable OOBE Privacy Experience'
    Description = 'Stops Windows showing its privacy settings screen after an update, so that screen can''t change the settings Atlas applied.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE'; Name = 'DisablePrivacyExperience'; Type = 'DWord'; Data = 1 }
    )
}
