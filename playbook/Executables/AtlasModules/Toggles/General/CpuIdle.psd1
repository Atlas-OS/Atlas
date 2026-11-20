@{
    Name        = 'CpuIdle'
    Description = 'Turns processor idle states on or off through the processor idle disable power setting. Disable Idle sets it to 1 and Enable Idle sets it to 0. On processors with Hyper-Threading or SMT, Atlas refuses Disable, and updates skip an earlier Disable record without changing the power setting.'
    Elevation   = 'Admin'
    Script      = 'CpuIdle.ps1'
    States      = @(
        @{
            Name             = 'Disable'
            StateValue       = 0
            Launcher         = '3. General Configuration\CPU Idle\Disable Idle.cmd'
            Reboot           = 'None'
            MachineAction    = 'Disable-AtlasCpuIdle'
            ReplayApplicable = 'Test-AtlasCpuIdleDisableSupported'
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
