@{
    Name        = 'Disable Dynamic Lighting'
    Description = 'Turns off Dynamic Lighting, which lets Windows control the RGB lighting on compatible devices.'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Lighting'; Name = 'AmbientLightingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
