@{
    Name        = 'Disable Dynamic Lighting'
    Description = 'Disables Dynamic Lighting by default'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the value is harmless
    # on Windows 10, where Dynamic Lighting does not exist.
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Lighting'; Name = 'AmbientLightingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
