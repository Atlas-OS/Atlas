@{
    Name        = 'Disallow Themes to Change Certain Personalized Features'
    Description = 'Stops themes changing your mouse pointers and desktop icons, so a theme changes only its wallpaper, colours and sounds.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes'; Name = 'ThemeChangesMousePointers'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes'; Name = 'ThemeChangesDesktopIcons'; Type = 'DWord'; Data = 0 }
    )
}
