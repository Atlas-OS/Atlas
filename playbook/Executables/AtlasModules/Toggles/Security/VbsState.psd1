@{
    Name        = 'VbsState'
    Description = 'Documented Virtualization-Based Security and memory-integrity configuration.'
    Elevation   = 'Admin'
    Script      = 'VbsState.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '7. Security\Core Isolation (VBS)\Disable VBS.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasVbsState'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '7. Security\Core Isolation (VBS)\Enable VBS.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasVbsState'
        }
    )
}
