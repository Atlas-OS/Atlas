@{
    Name        = 'TakeOwnership'
    Description = 'The Take Ownership context menu entries. Each state is applied from its .reg file under Scripts\Registry\TakeOwnership.'
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
