@{
    Name        = 'Show More Pins in Start'
    Description = 'Shows more pins in the Start Menu, meaning less recommendations'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Start_Layout'; Type = 'DWord'; Data = 1 }
    )
}
