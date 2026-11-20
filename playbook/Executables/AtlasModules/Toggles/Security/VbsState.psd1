@{
    Name        = 'VbsState'
    Description = 'Turns Virtualisation-Based Security and Memory Integrity on or off through Microsoft''s documented settings.'
    Elevation   = 'Admin'
    Script      = 'VbsState.ps1'
    States      = @(
        @{
            Name             = 'Disable'
            StateValue       = 0
            Launcher         = '7. Security\Core Isolation (VBS)\Disable VBS.cmd'
            Reboot           = 'Recommend'
            MachineAction    = 'Set-AtlasVbsState'
            ReplayApplicable = 'Test-AtlasVbsStateReplayApplicable'
        }
        @{
            Name             = 'Enable'
            StateValue       = 1
            Launcher         = '7. Security\Core Isolation (VBS)\Enable VBS.cmd'
            Reboot           = 'Recommend'
            MachineAction    = 'Set-AtlasVbsState'
            ReplayApplicable = 'Test-AtlasVbsStateReplayApplicable'
        }
    )
}
