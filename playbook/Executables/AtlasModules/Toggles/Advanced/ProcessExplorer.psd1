@{
    Name        = 'ProcessExplorer'
    Description = 'Replaces Task Manager with Sysinternals Process Explorer, or restores Task Manager.'
    Elevation   = 'Admin'
    Script      = 'ProcessExplorer.ps1'
    States      = @(
        @{
            Name          = 'Install'
            StateValue    = 1
            Launcher      = '6. Advanced Configuration\Process Explorer\Install Process Explorer.cmd'
            Reboot        = 'None'
            MachineAction = 'Install-AtlasProcessExplorer'
            UserAction    = 'Set-AtlasProcessExplorerUserPreference'
        }
        @{
            Name          = 'Uninstall'
            StateValue    = 0
            Launcher      = '6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.cmd'
            Reboot        = 'None'
            MachineAction = 'Uninstall-AtlasProcessExplorer'
        }
    )
}
