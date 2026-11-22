@{
    Name        = 'Disable Wallpaper Compression'
    Description = 'Stops Windows compressing JPEG wallpapers, so they show at full quality.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'JPEGImportQuality'; Type = 'DWord'; Data = 100 }
    )
}
