@{
    Name        = 'Disable Dynamic Lighting'
    Description = 'Disables Dynamic Lighting by default'
    MinBuild    = 22000
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Lighting'; Name = 'AmbientLightingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
