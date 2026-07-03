@{
    Name        = 'Show More Pins in Start'
    Description = 'Shows more pins in the Start Menu, meaning less recommendations'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the value is harmless
    # on Windows 10, whose Start Menu has no pins/recommendations layout setting.
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_Layout'; Type = 'DWord'; Data = 1 }
    )
}
