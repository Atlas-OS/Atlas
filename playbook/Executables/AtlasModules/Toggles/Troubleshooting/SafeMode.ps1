# Toggle: Safe Mode boot configuration.
@{
    Name      = 'SafeMode'
    Elevation = 'Admin'
    # Safe mode is a transient troubleshooting state: never record it, so an upgrade's
    # toggle re-apply can never silently boot the machine back into safe mode (e.g. when
    # the user entered via this launcher but exited via msconfig, leaving a stale record).
    NoStateRecord = $true
    States    = [ordered]@{
        Minimal       = @{
            StateValue = 3
            Launcher        = '9. Troubleshooting\Safe Mode\Safe Mode.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_3.cmd'
            Reboot          = 'Recommend'
            Action     = {
                param($Toggle)
                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SafeMode.ps1') -Mode Minimal
            }
        }
        CommandPrompt = @{
            StateValue = 1
            Launcher        = '9. Troubleshooting\Safe Mode\Safe Mode with Command Prompt.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_1.cmd'
            Reboot          = 'Recommend'
            Action     = {
                param($Toggle)
                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SafeMode.ps1') -Mode CommandPrompt
            }
        }
        Networking    = @{
            StateValue = 2
            Launcher        = '9. Troubleshooting\Safe Mode\Safe Mode with Networking.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_2.cmd'
            Reboot          = 'Recommend'
            Action     = {
                param($Toggle)
                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SafeMode.ps1') -Mode Networking
            }
        }
        Exit          = @{
            StateValue = 0
            Launcher        = '9. Troubleshooting\Safe Mode\Exit Safe Mode.cmd'
            ToolboxLauncher = 'ConfigurationServices\SafeMode\SafeMode_0.cmd'
            Reboot          = 'Recommend'
            Action     = {
                param($Toggle)
                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SafeMode.ps1') -Mode Exit
            }
        }
    }
}
