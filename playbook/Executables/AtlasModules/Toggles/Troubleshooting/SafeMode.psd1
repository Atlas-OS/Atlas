@{
    Name          = 'SafeMode'
    Description   = 'Safe Mode boot configuration. Safe mode is a transient troubleshooting state, so it is never recorded: an upgrade replay must never boot the machine back into safe mode from a stale record.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Script        = 'SafeMode.ps1'
    States        = @(
        @{
            Name            = 'Minimal'
            Launcher        = '9. Troubleshooting\Safe Mode\Safe Mode.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_3.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Set-AtlasSafeModeBoot'
        }
        @{
            Name            = 'CommandPrompt'
            Launcher        = '9. Troubleshooting\Safe Mode\Safe Mode with Command Prompt.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_1.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Set-AtlasSafeModeBoot'
        }
        @{
            Name            = 'Networking'
            Launcher        = '9. Troubleshooting\Safe Mode\Safe Mode with Networking.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_2.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Set-AtlasSafeModeBoot'
        }
        @{
            Name            = 'Exit'
            Launcher        = '9. Troubleshooting\Safe Mode\Exit Safe Mode.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_0.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Set-AtlasSafeModeBoot'
        }
    )
}
