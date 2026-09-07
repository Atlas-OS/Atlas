@{
    Name        = 'VerboseMessages'
    Description = 'Verbose (detailed) startup and shutdown status messages.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Verbose Status Messages\Disable Verbose Messages (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'verbosestatus'; Operation = 'Delete' }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Verbose Status Messages\Enable Verbose Messages.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'verbosestatus'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
