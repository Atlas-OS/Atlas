@{
    Name        = 'Sleep'
    Description = 'Sleep power-scheme settings, with an optional hibernation follow-up on an interactive disable.'
    Elevation   = 'Admin'
    Script      = 'Sleep.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\Sleep\Disable Sleep.cmd'
            Reboot        = 'None'
            MachineAction = 'Set-AtlasSleepState'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\Sleep\Enable Sleep (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Set-AtlasSleepState'
        }
    )
}
