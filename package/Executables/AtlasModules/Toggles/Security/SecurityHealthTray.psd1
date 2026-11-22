@{
    Name        = 'SecurityHealthTray'
    # Each state imports its .reg file from Scripts\Registry\SecurityHealthTray.
    Description = 'Adds or removes the Windows Security notification icon from startup.'
    Elevation   = 'Admin'
    Script      = 'SecurityHealthTray.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '7. Security\Defender\Security Health Tray\Remove Security Tray from Startup (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Set-AtlasSecurityHealthTrayStartup'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '7. Security\Defender\Security Health Tray\Add Security Tray to Startup.cmd'
            Reboot        = 'None'
            MachineAction = 'Set-AtlasSecurityHealthTrayStartup'
        }
    )
}
