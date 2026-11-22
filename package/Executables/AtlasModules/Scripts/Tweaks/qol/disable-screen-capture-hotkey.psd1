@{
    Name        = 'Disable Screen Capture Hotkey'
    Description = 'Stops the Print Screen key opening screen capture once Snipping Tool is removed.'
    Option      = 'remove-snipping-tool'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Keyboard'; Name = 'PrintScreenKeyForSnippingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
