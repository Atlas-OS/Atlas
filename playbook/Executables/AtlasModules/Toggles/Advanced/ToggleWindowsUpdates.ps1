# Toggle: Windows Update services, scheduled tasks and policies (single-launcher menu).
# Converted from 'AtlasDesktop\6. Advanced Configuration\Toggle Windows Updates\Toggle Windows Updates.cmd'.
#
# Single .cmd with an in-script Disable/Enable menu, so this is a Menu definition. The
# original showed a "(current)" marker computed from the live service state; the engine's
# generic menu can't render that, so static labels are used (cosmetic only). On /silent the
# original re-applied the recorded state; the engine does the same via the recorded state
# (upgrade re-apply only re-runs state != 0, i.e. Enable), so no SilentDefault is declared -
# a bare silent call with no recorded state is a no-op path that never occurs for a menu.
@{
    Name      = 'ToggleWindowsUpdates'
    Elevation = 'Admin'
    Menu      = $true
    Launcher  = '6. Advanced Configuration\Toggle Windows Updates\Toggle Windows Updates.cmd'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            MenuLabel  = 'Disable Windows Updates'
            Reboot     = 'Prompt'
            Action     = {
                param($Toggle)

                Write-Host 'Disabling Windows Update service and scheduled tasks...'
                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SetServiceStartup.ps1'
                $sc = "$($Toggle.WinDir)\System32\sc.exe"
                $schtasks = "$($Toggle.WinDir)\System32\schtasks.exe"

                & $sc stop wuauserv 2>$null | Out-Null
                & $setSvc -Name 'wuauserv' -Start 4
                & $sc stop UsoSvc 2>$null | Out-Null
                & $setSvc -Name 'UsoSvc' -Start 4
                & $setSvc -Name 'WaaSMedicSvc' -Start 4
                & $sc stop WaaSMedicSvc 2>$null | Out-Null

                foreach ($task in @(
                    'Microsoft\Windows\WindowsUpdate\sih'
                    'Microsoft\Windows\WindowsUpdate\sihboot'
                    'Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
                    'Microsoft\Windows\UpdateOrchestrator\USO_UxBroker'
                    'Microsoft\Windows\UpdateOrchestrator\Reboot'
                )) {
                    & $schtasks /Change /TN $task /Disable 2>$null | Out-Null
                }

                $wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
                if (-not (Test-Path -LiteralPath $wu)) { New-Item -Path $wu -Force | Out-Null }
                New-ItemProperty -LiteralPath $wu -Name 'DisableWindowsUpdateAccess' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $wu -Name 'DoNotConnectToWindowsUpdateInternetLocations' -Value 1 -PropertyType DWord -Force | Out-Null
                $wuAu = "$wu\AU"
                if (-not (Test-Path -LiteralPath $wuAu)) { New-Item -Path $wuAu -Force | Out-Null }
                New-ItemProperty -LiteralPath $wuAu -Name 'NoAutoUpdate' -Value 1 -PropertyType DWord -Force | Out-Null

                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SettingsPages.ps1') hide windowsupdate -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host 'Windows Updates have been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            MenuLabel  = 'Enable Windows Updates'
            Reboot     = 'Prompt'
            Action     = {
                param($Toggle)

                Write-Host 'Enabling Windows Update service and scheduled tasks...'
                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SetServiceStartup.ps1'
                $sc = "$($Toggle.WinDir)\System32\sc.exe"
                $schtasks = "$($Toggle.WinDir)\System32\schtasks.exe"

                & $setSvc -Name 'wuauserv' -Start 3
                & $sc start wuauserv 2>$null | Out-Null
                & $setSvc -Name 'UsoSvc' -Start 3
                & $sc start UsoSvc 2>$null | Out-Null
                & $setSvc -Name 'WaaSMedicSvc' -Start 3
                & $sc start WaaSMedicSvc 2>$null | Out-Null

                foreach ($task in @(
                    'Microsoft\Windows\WindowsUpdate\sih'
                    'Microsoft\Windows\WindowsUpdate\sihboot'
                    'Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
                    'Microsoft\Windows\UpdateOrchestrator\USO_UxBroker'
                    'Microsoft\Windows\UpdateOrchestrator\Reboot'
                )) {
                    & $schtasks /Change /TN $task /Enable 2>$null | Out-Null
                }

                $wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
                Remove-ItemProperty -LiteralPath $wu -Name 'DisableWindowsUpdateAccess' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $wu -Name 'DoNotConnectToWindowsUpdateInternetLocations' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath "$wu\AU" -Name 'NoAutoUpdate' -Force -ErrorAction SilentlyContinue

                & (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SettingsPages.ps1') unhide windowsupdate -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host 'Windows Updates have been enabled.'
                }
            }
        }
    }
}
