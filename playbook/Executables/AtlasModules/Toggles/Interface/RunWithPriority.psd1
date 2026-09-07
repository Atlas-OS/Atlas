@{
    Name        = 'RunWithPriority'
    Description = 'The Run with priority cascading entry in the .exe context menu.'
    Elevation   = 'Admin'
    Script      = 'RunWithPriority.ps1'
    States      = @(
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '4. Interface Tweaks\Context Menus\Run With Priority\Add Run With Priority In Context Menu.cmd'
            Reboot        = 'None'
            MachineAction = 'Add-AtlasRunWithPriorityContextMenu'
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Run With Priority\Remove Run With Priority In Context Menu (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Classes\exefile\Shell\Priority'; Operation = 'DeleteKey' }
            )
        }
    )
}
