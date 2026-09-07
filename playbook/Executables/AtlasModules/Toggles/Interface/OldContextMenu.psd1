@{
    Name        = 'OldContextMenu'
    Description = 'Windows 11 file context menu: the old full menu or the new compact menu.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd'
            Reboot     = 'RestartExplorer'
            # The old menu only activates when the InprocServer32 DEFAULT value is an
            # empty string; a bare key ('value not set') leaves the modern menu.
            Registry   = @(
                @{ Path = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name = ''; Type = 'String'; Data = '' }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Windows 11\New Context Menu.cmd'
            Reboot     = 'RestartExplorer'
            Registry   = @(
                @{ Path = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'; Operation = 'DeleteKey' }
            )
        }
    )
}
