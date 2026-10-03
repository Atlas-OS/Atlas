@{
    Name        = 'CpuIdle'
    Description = 'Processor idle-disable power setting. Disable Idle sets powercfg to 1; Enable Idle sets it to 0. On Hyper-Threading/SMT systems, manual disable requests are rejected and old disable records are skipped during upgrades without changing the power setting.'
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
