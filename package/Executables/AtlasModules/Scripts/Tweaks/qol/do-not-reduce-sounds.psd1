@{
    Name        = 'Do Not Reduce Sounds While in a Call'
    Description = 'Stops Windows lowering other sounds while you''re in a call.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Multimedia\Audio'; Name = 'UserDuckingPreference'; Type = 'DWord'; Data = 3 }
    )
}
