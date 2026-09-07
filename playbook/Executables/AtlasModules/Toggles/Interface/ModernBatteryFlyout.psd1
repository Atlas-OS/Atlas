@{
    Name        = 'ModernBatteryFlyout'
    Description = 'Modern or old (Windows 8-style) battery flyout.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Old Flyouts\Battery Flyout\Modern Battery Flyout (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'; Name = 'UseWin32BatteryFlyout'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Old Flyouts\Battery Flyout\Old Battery Flyout.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'; Name = 'UseWin32BatteryFlyout'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
