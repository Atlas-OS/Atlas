@{
    Name        = 'FileSharing'
    # Both states use the same Atlas.Network helpers as the fresh install.
    Description = 'Turns file sharing on or off: network discovery, SMB and the NetBIOS bindings. Enable can also add Network to the File Explorer navigation pane.'
    Elevation   = 'Admin'
    Script      = 'FileSharing.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\File Sharing\Disable File Sharing (default).cmd'
            Reboot        = 'Prompt'
            MachineAction = 'Set-AtlasFileSharingMachineState'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\File Sharing\Enable File Sharing.cmd'
            Reboot        = 'Prompt'
            MachineAction = 'Set-AtlasFileSharingMachineState'
            UserAction    = 'Add-AtlasFileSharingNetworkNavigationPane'
        }
    )
}
