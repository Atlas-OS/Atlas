# Toggle: Microsoft Copilot (taskbar button / app + policy).
#
# Both launchers restart Explorer to refresh the taskbar (Reboot='RestartExplorer'); the
# engine skips that restart when invoked with /noAction. Copilot requires an installed
# Edge installation, and on 24H2 it is delivered as a Store app installed through the
# repository's trusted WinGet resolver.
@{
    Name      = 'Copilot'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher        = '3. General Configuration\AI Features\Microsoft Copilot\Disable Microsoft Copilot (default).cmd'
            ToolboxLauncher = 'Scripts\Copilot\DisableMicrosoftCopilot.cmd'
            Reboot          = 'RestartExplorer'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Write-Host 'Disabling and uninstalling Copilot...'

                $appxManifest = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Modules\Atlas.Appx\Atlas.Appx.psd1'
                )
                if (-not [IO.File]::Exists($appxManifest)) {
                    throw "Copilot: the Atlas.Appx module is missing at '$appxManifest'."
                }

                Import-Module -Name $appxManifest -Force -ErrorAction Stop
                Invoke-AtlasAppxRemovalPlan -Definition @(
                    [pscustomobject]@{
                        Name         = 'Microsoft.Copilot*'
                        Option       = $null
                        IgnoreErrors = $false
                    }
                )
            }
            UserAction = {
                param($Toggle)

                $registryManifest = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Modules\Atlas.Registry\Atlas.Registry.psd1'
                )
                if (-not [IO.File]::Exists($registryManifest)) {
                    throw "Copilot: the Atlas.Registry module is missing at '$registryManifest'."
                }
                Import-Module -Name $registryManifest -Force -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Type DWord -Data 1
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher        = '3. General Configuration\AI Features\Microsoft Copilot\Enable Microsoft Copilot.cmd'
            ToolboxLauncher = 'Scripts\Copilot\Enable Microsoft Copilot.cmd'
            Reboot          = 'RestartExplorer'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $programFilesX86 = [Environment]::GetFolderPath(
                    [Environment+SpecialFolder]::ProgramFilesX86
                )
                if ([string]::IsNullOrWhiteSpace($programFilesX86)) {
                    throw 'Copilot: the 32-bit Program Files directory is unavailable.'
                }

                $edgePath = [IO.Path]::Combine(
                    $programFilesX86,
                    'Microsoft\Edge\Application\msedge.exe'
                )
                if (-not [IO.File]::Exists($edgePath)) {
                    throw "Copilot: Microsoft Edge is unavailable at '$edgePath'."
                }
            }
            UserAction = {
                param($Toggle)

                $trustBootstrap = [IO.Path]::Combine($Toggle.ScriptsPath, 'Internal', 'Initialize-PowerShellTrust.ps1')
                if (-not [IO.File]::Exists($trustBootstrap)) {
                    throw "Copilot: the PowerShell trust bootstrap is missing at '$trustBootstrap'."
                }
                . $trustBootstrap

                $registryManifest = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Modules\Atlas.Registry\Atlas.Registry.psd1'
                )
                if (-not [IO.File]::Exists($registryManifest)) {
                    throw "Copilot: the Atlas.Registry module is missing at '$registryManifest'."
                }
                Import-Module -Name $registryManifest -Force -ErrorAction Stop

                Write-Host 'Enabling Copilot...'

                # If the taskbar Copilot button is unavailable (24H2+), Copilot ships as an
                # app installed via winget; otherwise just re-show the taskbar button.
                $available = Get-ItemPropertyValue `
                    -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Copilot' `
                    -Name 'IsCopilotAvailable' `
                    -ErrorAction SilentlyContinue
                $taskbarCopilotUnavailable = (
                    $null -ne $available -and [int]$available -eq 0
                )

                if ($taskbarCopilotUnavailable) {
                    if (-not $Toggle.Silent) {
                        Write-Host "NOTE: Copilot on the taskbar isn't available, the app will be installed instead."
                    }
                    $downloadIntegrity = [IO.Path]::Combine($Toggle.ScriptsPath, 'Internal', 'Download-Integrity.ps1')
                    if (-not [IO.File]::Exists($downloadIntegrity)) {
                        throw "Copilot: the download-integrity helper is missing at '$downloadIntegrity'."
                    }
                    . $downloadIntegrity
                    $wingetPath = Get-AtlasTrustedWingetPath
                    Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
                    Write-Host 'Installing Copilot...'
                    [void](Invoke-AtlasToggleNativeCommand `
                            -FilePath $wingetPath `
                            -ArgumentList ([string[]]@(
                                    'install',
                                    '--exact',
                                    '--id', '9NHT9RB2F4HD',
                                    '--source', 'msstore',
                                    '--uninstall-previous',
                                    '--silent',
                                    '--accept-source-agreements',
                                    '--accept-package-agreements',
                                    '--disable-interactivity'
                                )) `
                            -AllowedExitCodes ([int[]]@(0)))
                }
                else {
                    Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Type DWord -Data 1
                }

                Remove-AtlasRegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot'
            }
        }
    }
}
