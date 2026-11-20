@{
    Name        = 'Do Not Show Edge Tabs in Alt-Tab'
    Description = 'Sets Alt+Tab to show open windows only, so individual Edge tabs don''t crowd it.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'MultiTaskingAltTabFilter'; Type = 'DWord'; Data = 3 }
    )
}
