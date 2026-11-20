@{
    Name        = 'TakeOwnership'
    # Each state imports its .reg file from Scripts\Registry\TakeOwnership.
    Description = 'Adds or removes Take Ownership in the context menu.'
    Elevation   = 'Admin'
    Script      = 'TakeOwnership.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '4. Interface Tweaks\Context Menus\Take Ownership\Remove Take Ownership to Context Menu (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Import-AtlasTakeOwnershipContextMenu'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '4. Interface Tweaks\Context Menus\Take Ownership\Add Take Ownership to Context Menu.cmd'
            Reboot        = 'None'
            MachineAction = 'Import-AtlasTakeOwnershipContextMenu'
        }
    )
}
