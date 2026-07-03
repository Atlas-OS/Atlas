@{
    Name        = 'Disable Use Check Boxes to Select Items'
    Description = 'Disables check boxes in File Explorer to select items for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'AutoCheckSelect'; Type = 'DWord'; Data = 0 }
    )
}
