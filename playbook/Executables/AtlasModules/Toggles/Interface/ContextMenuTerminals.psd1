@{
    Name        = 'ContextMenuTerminals'
    # Each state imports its .reg file from Scripts\Registry\Terminals.
    Description = 'Removes the Terminals context menu, or adds it with or without Windows Terminal.'
    Elevation   = 'Admin'
    Script      = 'ContextMenuTerminals.ps1'
    States      = @(
        @{
            Name          = 'Remove'
            StateValue    = 0
            Launcher      = '4. Interface Tweaks\Context Menus\Terminals\Remove Terminals Context Menu (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Import-AtlasTerminalsContextMenu'
        }
        @{
            Name          = 'Add'
            StateValue    = 1
            Launcher      = '4. Interface Tweaks\Context Menus\Terminals\Add Terminals.cmd'
            Reboot        = 'None'
            MachineAction = 'Import-AtlasTerminalsContextMenu'
        }
        @{
            Name          = 'AddNoWindowsTerminal'
            StateValue    = 2
            Launcher      = '4. Interface Tweaks\Context Menus\Terminals\Add Terminals (no Windows Terminal).cmd'
            Reboot        = 'None'
            MachineAction = 'Import-AtlasTerminalsContextMenu'
        }
    )
}
