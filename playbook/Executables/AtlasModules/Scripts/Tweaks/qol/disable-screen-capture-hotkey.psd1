@{
    Name        = 'Disable Screen Capture Hotkey'
    Description = 'Disables using the print screen key to open Screen Capture when Snipping Tool is removed'
    Option      = 'remove-snipping-tool'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Keyboard'; Name = 'PrintScreenKeyForSnippingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
