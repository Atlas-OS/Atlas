# Toggle: Windows Update services, scheduled tasks and policies (single-launcher menu).
#
# The engine's generic menu can't render a "(current)" marker computed from the live
# service state, so static labels are used (cosmetic only). Both choices are explicitly
# machine-replayable; No SilentDefault is needed because reapply resolves the recorded
# state rather than choosing a default.
@{
    Name      = 'ToggleWindowsUpdates'
    Elevation = 'Admin'
    Menu      = $true
    Launcher  = '6. Advanced Configuration\Toggle Windows Updates\Toggle Windows Updates.cmd'
    States    = [ordered]@{
        Disable = @{
            StateValue  = 0
            ReplayScope = 'Machine'
            MenuLabel   = 'Disable Windows Updates'
            Reboot      = 'Prompt'
            Action      = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Import-Module -Name ScheduledTasks -ErrorAction Stop

                Write-Host 'Disabling Windows Update service and scheduled tasks...'
                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                foreach ($serviceName in @('wuauserv', 'UsoSvc', 'WaaSMedicSvc')) {
                    $service = Get-Service -Name $serviceName -ErrorAction Stop
                    if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
                        Stop-Service -Name $serviceName -Force -ErrorAction Stop
                    }
                    & $setSvc -Name $serviceName -Start 4
                }

                $allTasks = @(Get-ScheduledTask -ErrorAction Stop)
                foreach ($taskPath in @(
                    'Microsoft\Windows\WindowsUpdate\sih'
                    'Microsoft\Windows\WindowsUpdate\sihboot'
                    'Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
                    'Microsoft\Windows\UpdateOrchestrator\USO_UxBroker'
                    'Microsoft\Windows\UpdateOrchestrator\Reboot'
                )) {
                    $task = $allTasks | Where-Object {
                        ([string]::Concat([string]$_.TaskPath, [string]$_.TaskName)).Trim([char]'\') -ieq $taskPath
                    } | Select-Object -First 1
                    if ($null -eq $task) {
                        Write-Verbose "ToggleWindowsUpdates: optional scheduled task '$taskPath' is not present on this Windows build."
                        continue
                    }

                    Disable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
                }

                $wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
                Set-AtlasRegistryValue -Path $wu -Name 'DisableWindowsUpdateAccess' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path $wu -Name 'DoNotConnectToWindowsUpdateInternetLocations' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path "$wu\AU" -Name 'NoAutoUpdate' -Type DWord -Data 1

                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1') hide windowsupdate -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host 'Windows Updates have been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue  = 1
            ReplayScope = 'Machine'
            MenuLabel   = 'Enable Windows Updates'
            Reboot      = 'Prompt'
            Action      = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Import-Module -Name ScheduledTasks -ErrorAction Stop

                Write-Host 'Enabling Windows Update service and scheduled tasks...'
                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                foreach ($serviceName in @('wuauserv', 'UsoSvc', 'WaaSMedicSvc')) {
                    & $setSvc -Name $serviceName -Start 3

                    $service = Get-Service -Name $serviceName -ErrorAction Stop
                    if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
                        Start-Service -Name $serviceName -ErrorAction Stop
                    }
                }

                $allTasks = @(Get-ScheduledTask -ErrorAction Stop)
                foreach ($taskPath in @(
                    'Microsoft\Windows\WindowsUpdate\sih'
                    'Microsoft\Windows\WindowsUpdate\sihboot'
                    'Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
                    'Microsoft\Windows\UpdateOrchestrator\USO_UxBroker'
                    'Microsoft\Windows\UpdateOrchestrator\Reboot'
                )) {
                    $task = $allTasks | Where-Object {
                        ([string]::Concat([string]$_.TaskPath, [string]$_.TaskName)).Trim([char]'\') -ieq $taskPath
                    } | Select-Object -First 1
                    if ($null -eq $task) {
                        Write-Verbose "ToggleWindowsUpdates: optional scheduled task '$taskPath' is not present on this Windows build."
                        continue
                    }

                    Enable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
                }

                $wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
                Remove-AtlasRegistryValue -Path $wu -Name 'DisableWindowsUpdateAccess'
                Remove-AtlasRegistryValue -Path $wu -Name 'DoNotConnectToWindowsUpdateInternetLocations'
                Remove-AtlasRegistryValue -Path "$wu\AU" -Name 'NoAutoUpdate'

                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1') unhide windowsupdate -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host 'Windows Updates have been enabled.'
                }
            }
        }
    }
}
