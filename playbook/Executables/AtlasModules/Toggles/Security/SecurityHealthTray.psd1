@{
    Name        = 'SecurityHealthTray'
    Description = 'Windows Security (Defender) tray icon startup entry, applied from the shipped .reg assets.'
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
