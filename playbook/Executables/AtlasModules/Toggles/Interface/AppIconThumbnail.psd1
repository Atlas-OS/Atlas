@{
    Name        = 'AppIconThumbnail'
    Description = 'Application icon overlays on File Explorer thumbnails.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\App Icons on Thumbnails\Disable App Icons on Thumbnails.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowTypeOverlay'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\App Icons on Thumbnails\Enable App Icons on Thumbnails (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowTypeOverlay'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
