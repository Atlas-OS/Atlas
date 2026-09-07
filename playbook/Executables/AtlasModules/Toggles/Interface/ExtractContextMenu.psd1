@{
    Name        = 'ExtractContextMenu'
    Description = 'Extract entry in the file context menu, controlled by blocking or unblocking the archive shell extensions.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Context Menus\Extract\Add Extract.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{BD472F60-27FA-11cf-B8B4-444553540000}'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{EE07CEF5-3441-4CFB-870A-4002C724783A}'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}'; Operation = 'Delete' }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Extract\Remove Extract (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}'; Type = 'String'; Data = '' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{BD472F60-27FA-11cf-B8B4-444553540000}'; Type = 'String'; Data = '' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{EE07CEF5-3441-4CFB-870A-4002C724783A}'; Type = 'String'; Data = '' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'; Name = '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}'; Type = 'String'; Data = '' }
            )
        }
    )
}
