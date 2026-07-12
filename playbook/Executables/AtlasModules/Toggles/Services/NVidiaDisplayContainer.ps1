# Toggle: NVIDIA Display Container LS service.
@{
    Name      = 'NVidiaDisplayContainer'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher        = '6. Advanced Configuration\Services\NVIDIA Display Container\Disable NVIDIA Display Container LS.cmd'
            ToolboxLauncher = 'Scripts\NVidia\DisableNVIDIADisplayContainerLS.cmd'
            Reboot          = 'None'
            Action     = {
                param($Toggle)

                if (-not (Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NVDisplay.ContainerLocalSystem')) {
                    throw 'NVIDIA Display Container LS is not installed; the requested state is not applicable and was not recorded.'
                }

                if (-not $Toggle.Silent) {
                    Write-Host "Disabling the 'NVIDIA Display Container LS' service will stop the NVIDIA Control Panel from working."
                    Write-Host 'It will most likely break other NVIDIA driver features as well.'
                    Write-Host 'These scripts are aimed at users that have a stripped driver, and people that barely touch the NVIDIA Control Panel.'
                    Write-Host ''
                    Write-Host 'You can enable the NVIDIA Control Panel and the service again by running the enable script.'
                    Write-Host 'Additionally, you can add a context menu to the desktop with another script in the Atlas folder.'
                    Write-Host ''
                    Write-Host "See 'Must Read First' for more info."
                }

                $setServiceStartup = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setServiceStartup -Name 'NVDisplay.ContainerLocalSystem' -Start 4
                $service = Get-Service -Name 'NVDisplay.ContainerLocalSystem' -ErrorAction Stop
                if ($service.Status -ne [ServiceProcess.ServiceControllerStatus]::Stopped) {
                    Stop-Service -InputObject $service -Force -ErrorAction Stop
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher        = '6. Advanced Configuration\Services\NVIDIA Display Container\Enable NVIDIA Display Container LS (default).cmd'
            ToolboxLauncher = 'Scripts\NVidia\EnableNVIDIADisplayContainerLS.cmd'
            Reboot          = 'None'
            Action     = {
                param($Toggle)

                if (-not (Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NVDisplay.ContainerLocalSystem')) {
                    throw 'NVIDIA Display Container LS is not installed; the requested state is not applicable and was not recorded.'
                }

                $setServiceStartup = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setServiceStartup -Name 'NVDisplay.ContainerLocalSystem' -Start 2
                $service = Get-Service -Name 'NVDisplay.ContainerLocalSystem' -ErrorAction Stop
                if ($service.Status -ne [ServiceProcess.ServiceControllerStatus]::Running) {
                    Start-Service -InputObject $service -ErrorAction Stop
                }
            }
        }
    }
}
