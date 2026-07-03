@{
    Name        = 'Disable Wallpaper Compression'
    Description = 'Disables wallpaper compression so that your wallpaper is always in its full quality'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'JPEGImportQuality'; Type = 'DWord'; Data = 100 }
    )
}
