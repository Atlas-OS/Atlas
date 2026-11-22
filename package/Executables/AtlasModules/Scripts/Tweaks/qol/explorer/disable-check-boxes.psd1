@{
    Name        = 'Disable Use Check Boxes to Select Items'
    Description = 'Turns off check boxes for selecting items in File Explorer.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'AutoCheckSelect'; Type = 'DWord'; Data = 0 }
    )
}
