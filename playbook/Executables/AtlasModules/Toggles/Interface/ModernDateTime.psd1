@{
    Name        = 'ModernDateTime'
    Description = 'Modern or old (Windows 8-style) date and time (tray clock) flyout.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Old Flyouts\Date and Time Flyout\Modern Date and Time Flyout (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'; Name = 'UseWin32TrayClockExperience'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Old Flyouts\Date and Time Flyout\Old Date and Time Flyout.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'; Name = 'UseWin32TrayClockExperience'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
