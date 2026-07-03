@{
    Name        = 'Disallow Themes to Change Certain Personalized Features'
    Description = 'Disallows themes to change certain personalized features, as most of the time people only really apply themes for wallpapers or Windows style skins (custom themes)'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes'; Name = 'ThemeChangesMousePointers'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes'; Name = 'ThemeChangesDesktopIcons'; Type = 'DWord'; Data = 0 }
    )
}
