# Toggle: replace Task Manager with Sysinternals Process Explorer.
@{
    Name      = 'ProcessExplorer'
    Elevation = 'Admin'
    States    = [ordered]@{
        Install = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Process Explorer\Install Process Explorer.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $helper = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Internal',
                    'ProcessExplorer-Package.ps1'
                )
                if (-not [IO.File]::Exists($helper)) {
                    throw "ProcessExplorer: the package helper is missing at '$helper'."
                }
                . $helper

                $disablePcw = $true
                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host "The 'pcw' service is needed for Task Manager and performance counters."
                    Write-Host 'Disabling it may cause some performance tools to misbehave.'
                    $disablePcw = (Read-Host 'Would you like to disable it? [Y/N]') -match '^(y|yes)$'
                }

                Write-Host 'Installing Process Explorer...'
                Install-AtlasProcessExplorerPackage -DisablePcw:$disablePcw
                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, changes have been applied.'
                }
            }
            UserAction = {
                param($Toggle)

                $helper = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Internal',
                    'ProcessExplorer-Package.ps1'
                )
                if (-not [IO.File]::Exists($helper)) {
                    throw "ProcessExplorer: the package helper is missing at '$helper'."
                }
                . $helper
                Write-AtlasProcessExplorerUserPreference
            }
        }
        Uninstall = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $helper = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Internal',
                    'ProcessExplorer-Package.ps1'
                )
                if (-not [IO.File]::Exists($helper)) {
                    throw "ProcessExplorer: the package helper is missing at '$helper'."
                }
                . $helper

                Write-Host 'Uninstalling Process Explorer...'
                Uninstall-AtlasProcessExplorerPackage
                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, changes have been applied.'
                }
            }
            UserAction = { param($Toggle) }
        }
    }
}
