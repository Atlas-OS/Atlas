@{
    Name        = 'NetworkDiscovery'
    Description = 'Turns the network discovery services on or off. Enable turns on SMB first. Network profiles and the firewall discovery rules stay separate choices in Advanced sharing settings, and the Network Navigation Pane toggle controls whether File Explorer shows Network.'
    Elevation   = 'Admin'
    Warning     = 'Changes the network discovery services. While disabled, this PC can''t find or be found by other devices on the network.'
    Script      = 'NetworkDiscovery.ps1'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Services\Network Discovery\Disable Network Discovery Services.cmd'
            Reboot     = 'Recommend'
            Services   = @(
                @{ Name = 'fdPHost'; StartupType = 4 }
                @{ Name = 'FDResPub'; StartupType = 4 }
                @{ Name = 'lmhosts'; StartupType = 4 }
                @{ Name = 'SSDPSRV'; StartupType = 4 }
            )
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '6. Advanced Configuration\Services\Network Discovery\Enable Network Discovery Services (default).cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Enable-AtlasNetworkDiscoveryServices'
        }
    )
}
