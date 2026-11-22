@{
    Name          = 'ToggleDefender'
    # The menu runs in the administrator window, and its choice reaches the silent TrustedInstaller
    # broker as a fixed internal state.
    Description   = 'Removes or restores Windows Defender through the Atlas NoDefender package.'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    Script        = 'ToggleDefender.ps1'
    States        = @(
        @{
            Name             = 'Run'
            Launcher         = '7. Security\Defender\Toggle Defender.cmd'
            ToolboxLauncher  = 'Scripts\toggleDefender.cmd'
            Reboot           = 'Prompt'
            MachineAction    = 'Invoke-AtlasDefenderToggle'
            InteractiveState = 'Select-AtlasDefenderToggleState'
        }
        @{
            Name          = 'Disable'
            Internal      = $true
            NoStateRecord = $true
            MachineAction = 'Disable-AtlasDefenderToggle'
        }
        @{
            Name          = 'Enable'
            Internal      = $true
            NoStateRecord = $true
            MachineAction = 'Enable-AtlasDefenderToggle'
        }
    )
}
