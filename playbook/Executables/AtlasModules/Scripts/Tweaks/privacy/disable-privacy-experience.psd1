@{
    Name        = 'Disable OOBE Privacy Experience'
    Description = 'Disables the OOBE (Out of Box Experience) privacy configuration that you might see on updates not to override current settings'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE'; Name = 'DisablePrivacyExperience'; Type = 'DWord'; Data = 1 }
    )
}
