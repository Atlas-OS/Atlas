# Toggle: Microsoft Copilot (taskbar button / app + policy).
#
# Both launchers restart Explorer to refresh the taskbar (Reboot='RestartExplorer'); the
# engine skips that restart when invoked with /noAction. The Enable path uses the
# Test-EdgeState.cmd / Test-Winget.cmd helpers (Copilot needs Edge, and on 24H2 it is
# delivered as a Store app installed via winget).
@{
    Name      = 'Copilot'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher        = '3. General Configuration\AI Features\Microsoft Copilot\Disable Microsoft Copilot (default).cmd'
            ToolboxLauncher = 'Scripts\Copilot\DisableMicrosoftCopilot.cmd'
            Reboot          = 'RestartExplorer'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Write-Host 'Disabling and uninstalling Copilot...'
                Get-AppxPackage -AllUsers 'Microsoft.Copilot*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Data 1
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher        = '3. General Configuration\AI Features\Microsoft Copilot\Enable Microsoft Copilot.cmd'
            ToolboxLauncher = 'Scripts\Copilot\Enable Microsoft Copilot.cmd'
            Reboot          = 'RestartExplorer'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                # Copilot requires Microsoft Edge - reuse the shared Edge check helper.
                $edgeCheck = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Test-EdgeState.cmd'
                & "$env:ComSpec" /c "call `"$edgeCheck`" /edgeonly"
                if ($LASTEXITCODE -ne 0) {
                    return
                }

                Write-Host 'Enabling Copilot...'

                # If the taskbar Copilot button is unavailable (24H2+), Copilot ships as an
                # app installed via winget; otherwise just re-show the taskbar button.
                $copilotAvailable = $false
                $available = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Copilot' -Name 'IsCopilotAvailable' -ErrorAction SilentlyContinue).IsCopilotAvailable
                if ($null -ne $available -and [int]$available -eq 0) {
                    $copilotAvailable = $true
                }

                if ($copilotAvailable) {
                    if (-not $Toggle.Silent) {
                        Write-Host "NOTE: Copilot on the taskbar isn't available, the app will be installed instead."
                    }
                    $wingetCheck = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Test-Winget.cmd'
                    & "$env:ComSpec" /c "call `"$wingetCheck`" /nodashes"
                    if ($LASTEXITCODE -ne 0) {
                        return
                    }
                    Write-Host 'Installing Copilot...'
                    & winget install -e --id 9NHT9RB2F4HD --uninstall-previous -h --accept-source-agreements --accept-package-agreements --force --disable-interactivity | Out-Null
                }
                else {
                    Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Data 1
                }

                Remove-AtlasRegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot'
            }
        }
    }
}
