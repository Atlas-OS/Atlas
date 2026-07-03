@{
    Name        = 'Do Not Show Edge Tabs in Alt-Tab'
    Description = 'Sets the ''Alt + Tab shows'' option to ''Open windows only'', meaning that individual Edge tabs won''t be displayed, which would clutter the alt-tab interface'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'MultiTaskingAltTabFilter'; Type = 'DWord'; Data = 3 }
    )
}
