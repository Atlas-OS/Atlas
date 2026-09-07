@{
    Name        = 'CpuIdle'
    Description = 'Processor idle-disable power setting. The powercfg value is inverted relative to the toggle (Disable Idle sets it to 1, Enable Idle to 0), and Disable is rejected on Hyper-Threading/SMT systems without changing or recording the state.'
    Elevation   = 'Admin'
    Script      = 'CpuIdle.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\CPU Idle\Disable Idle.cmd'
            Reboot        = 'None'
            MachineAction = 'Disable-AtlasCpuIdle'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\CPU Idle\Enable Idle (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Enable-AtlasCpuIdle'
        }
    )
}
