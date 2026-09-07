@{
    Name        = 'ShortcutIcon'
    Description = 'Shortcut overlay icon: the default arrow, the classic arrow or none.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Default'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Shortcut Icon\Default Windows (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'; Name = '29'; Operation = 'Delete' }
            )
        }
        @{
            Name       = 'Classic'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Shortcut Icon\Classic.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'; Name = '29'; Type = 'String'; Data = 'C:\Windows\AtlasModules\Other\Classic.ico,0' }
            )
        }
        @{
            Name       = 'None'
            StateValue = 2
            Launcher   = '4. Interface Tweaks\Shortcut Icon\None (security risk).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'; Name = '29'; Type = 'String'; Data = 'C:\Windows\AtlasModules\Other\Blank.ico,0' }
            )
        }
    )
}
