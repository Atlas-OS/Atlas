@{
    Name        = 'Disable Screen Capture Hotkey'
    Description = 'Disables using the print screen key to open Screen Capture when Snipping Tool is removed'
    # The legacy tweaks.yml include line gated this tweak on the 'remove-snipping-tool' option.
    Option      = 'remove-snipping-tool'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Keyboard'; Name = 'PrintScreenKeyForSnippingEnabled'; Type = 'DWord'; Data = 0 }
    )
}
