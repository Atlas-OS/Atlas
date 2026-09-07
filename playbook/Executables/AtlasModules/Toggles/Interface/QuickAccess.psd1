@{
    Name        = 'QuickAccess'
    Description = 'Quick Access in File Explorer (HubMode hides it).'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Quick Access\Remove Quick Access.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'HubMode'; Type = 'DWord'; Data = 1 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Quick Access\Show Quick Access (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'HubMode'; Operation = 'Delete' }
            )
        }
    )
}
