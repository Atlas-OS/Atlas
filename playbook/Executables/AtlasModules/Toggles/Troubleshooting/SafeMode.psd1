@{
    Name          = 'SafeMode'
    # Safe mode is a passing troubleshooting state, so it's never recorded: update replay must never
    # start the PC in safe mode from an old record.
    Description   = 'Sets Windows to start in safe mode, with networking or with the command prompt, or to start normally again.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Script        = 'SafeMode.ps1'
    States        = @(
        @{
            Name          = 'Minimal'
            Launcher      = '9. Troubleshooting\Safe Mode\Safe Mode.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasSafeModeBoot'
        }
        @{
            Name          = 'CommandPrompt'
            Launcher      = '9. Troubleshooting\Safe Mode\Safe Mode with Command Prompt.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasSafeModeBoot'
        }
        @{
            Name          = 'Networking'
            Launcher      = '9. Troubleshooting\Safe Mode\Safe Mode with Networking.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasSafeModeBoot'
        }
        @{
            Name          = 'Exit'
            Launcher      = '9. Troubleshooting\Safe Mode\Exit Safe Mode.cmd'
            Reboot        = 'Recommend'
            MachineAction = 'Set-AtlasSafeModeBoot'
        }
    )
}
