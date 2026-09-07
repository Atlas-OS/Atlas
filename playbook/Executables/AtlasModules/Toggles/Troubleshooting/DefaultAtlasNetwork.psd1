@{
    Name        = 'DefaultAtlasNetwork'
    Description = 'Network adapter reset. Enable applies Atlas defaults; Disable restores Windows defaults. Both states share the Atlas.Network Set-AtlasNetworkDefaults implementation with the Toolbox.'
    Elevation   = 'Admin'
    NoStateRecord = $true
    Script      = 'DefaultAtlasNetwork.ps1'
    States      = @(
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '9. Troubleshooting\Network\Reset Network to Atlas Default.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasNetworkDefaultState'
        }
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '9. Troubleshooting\Network\Reset Network to Windows Default.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasNetworkDefaultState'
        }
    )
}
