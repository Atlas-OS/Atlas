@{
    Name        = 'Do Not Reduce Sounds While in a Call'
    Description = 'Makes it so that Windows does not reduce sounds in a call for QoL, as people generally wouldn''t want this behavior'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Multimedia\Audio'; Name = 'UserDuckingPreference'; Type = 'DWord'; Data = 3 }
    )
}
