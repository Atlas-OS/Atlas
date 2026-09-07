@{
    Name        = 'ModernVolumeFlyout'
    Description = 'Modern or old (Windows 8-style) volume flyout.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Old Flyouts\Volume Flyout\Modern Volume Flyout (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MTCUVC'; Name = 'EnableMtcUvc'; Operation = 'Delete' }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Old Flyouts\Volume Flyout\Old Volume Flyout.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MTCUVC'; Name = 'EnableMtcUvc'; Type = 'DWord'; Data = 0 }
            )
        }
    )
}
