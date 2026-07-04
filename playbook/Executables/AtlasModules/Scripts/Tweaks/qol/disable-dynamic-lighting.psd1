@{
    Name        = 'Disable Dynamic Lighting'
    Description = 'Disables Dynamic Lighting by default'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Lighting'; Name = 'AmbientLightingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
