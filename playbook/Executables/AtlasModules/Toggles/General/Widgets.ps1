# Toggle: Widgets / News and Interests feeds.
#
# The Edge/WebView helper and the ms-settings:taskbar page are gated to
# interactive mode so upgrade re-apply never blocks.
@{
    Name      = 'Widgets'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Widgets (News and Interests)\Disable Widgets (default).cmd'
            Reboot     = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerRefresh'
            Action     = {
                param($Toggle)

                $registryManifest = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Modules\Atlas.Registry\Atlas.Registry.psd1'
                )
                if (-not [IO.File]::Exists($registryManifest)) {
                    throw "Widgets: the Atlas.Registry module is missing at '$registryManifest'."
                }
                Import-Module -Name $registryManifest -ErrorAction Stop

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Disabling News and Interests (called Widgets in Windows 11)...'
                }

                Set-AtlasRegistryValue `
                    -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' `
                    -Name 'EnableFeeds' -Type DWord -Data 0
                Set-AtlasRegistryValue `
                    -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' `
                    -Name 'AllowNewsAndInterests' -Type DWord -Data 0

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Finished, changes have been applied.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Widgets (News and Interests)\Enable Widgets.cmd'
            Reboot     = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerRefresh'
            Action     = {
                param($Toggle)

                $registryManifest = [IO.Path]::Combine(
                    $Toggle.ScriptsPath,
                    'Modules\Atlas.Registry\Atlas.Registry.psd1'
                )
                if (-not [IO.File]::Exists($registryManifest)) {
                    throw "Widgets: the Atlas.Registry module is missing at '$registryManifest'."
                }
                Import-Module -Name $registryManifest -ErrorAction Stop

                if (-not $Toggle.Silent) {
                    $programFilesX86 = [Environment]::GetFolderPath(
                        [Environment+SpecialFolder]::ProgramFilesX86
                    )
                    if ([string]::IsNullOrWhiteSpace($programFilesX86) -or
                        -not [IO.Directory]::Exists($programFilesX86)) {
                        throw 'Widgets: the 32-bit Program Files directory is unavailable.'
                    }

                    $edgePath = [IO.Path]::Combine(
                        $programFilesX86,
                        'Microsoft\Edge\Application\msedge.exe'
                    )
                    $installEdge = -not [IO.File]::Exists($edgePath)

                    if ($installEdge) {
                        Write-Host 'Microsoft Edge is required to enable Widgets.'
                        $answer = Read-Host 'Would you like to install Edge? [Y/N]'
                        if ($answer -notmatch '^(?i:y|yes)$') {
                            throw 'Widgets: Microsoft Edge is unavailable and installation was declined.'
                        }
                    }

                    $edgeHelper = [IO.Path]::Combine(
                        $Toggle.ScriptsPath,
                        'Internal\Remove-Edge.ps1'
                    )
                    if (-not [IO.File]::Exists($edgeHelper)) {
                        throw "Widgets: the Edge helper is missing at '$edgeHelper'."
                    }

                    $windowsPowerShell = [IO.Path]::Combine(
                        $Toggle.WinDir,
                        'System32\WindowsPowerShell\v1.0\powershell.exe'
                    )
                    if (-not [IO.File]::Exists($windowsPowerShell)) {
                        throw "Widgets: Windows PowerShell is missing at '$windowsPowerShell'."
                    }

                    [string[]]$edgeArguments = @(
                        '-NoLogo',
                        '-NoProfile',
                        '-NonInteractive',
                        '-ExecutionPolicy', 'Bypass',
                        '-File', $edgeHelper,
                        '-NonInteractive',
                        '-InstallWebView'
                    )
                    if ($installEdge) {
                        $edgeArguments += '-InstallEdge'
                    }
                    [void](Invoke-AtlasToggleNativeCommand `
                            -FilePath $windowsPowerShell `
                            -ArgumentList $edgeArguments `
                            -AllowedExitCodes ([int[]]@(0)))

                    Write-Host ''
                    Write-Host 'Enabling News and Interests (called Widgets in Windows 11)...'
                }

                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -Name 'EnableFeeds'
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests'

                if (-not $Toggle.Silent) {
                    Start-Sleep -Seconds 3
                    Start-Process 'ms-settings:taskbar' -ErrorAction Stop
                    Write-Host ''
                    Write-Host 'Finished, you should be able to toggle News and Interests or Widgets in Settings.'
                }
            }
        }
    }
}
