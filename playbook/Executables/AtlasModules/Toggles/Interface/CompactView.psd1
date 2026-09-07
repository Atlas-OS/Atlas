@{
    Name        = 'CompactView'
    Description = 'Compact view (reduced item spacing) in File Explorer.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Compact View\Disable Compact View.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'UseCompactMode'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Compact View\Enable Compact View (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'UseCompactMode'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
