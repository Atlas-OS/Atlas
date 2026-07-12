# Toggle: Recent Items / app & document usage tracking.
@{
    Name      = 'RecentItems'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Unlock Recent Items\Disable Recent Items (default).cmd'
            Reboot     = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerAndSettingsRefresh'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Write-Host 'Disabling recent items...'

                $hklmExplorer = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hklmPolicies = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                foreach ($key in @($hklmExplorer, $hklmPolicies)) {
                    if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                }

                New-ItemProperty -LiteralPath $hklmExplorer -Name 'NoStartMenuMFUprogramsList' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmExplorer -Name 'NoRecentDocsHistory' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmPolicies -Name 'ShowOrHideMostUsedApps' -Value 2 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmPolicies -Name 'HideRecentlyAddedApps' -Value 1 -PropertyType DWord -Force | Out-Null

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages hide privacy-general -Silent:$Toggle.Silent -NoProcessCleanup
            }
            UserAction = {
                param($Toggle)

                $hkcuExplorer = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hkcuPolicies = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                $advanced = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                foreach ($key in @($hkcuExplorer, $hkcuPolicies, $advanced)) {
                    if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                }
                New-ItemProperty -LiteralPath $hkcuExplorer -Name 'NoInstrumentation' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hkcuExplorer -Name 'ClearRecentDocsOnExit' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hkcuExplorer -Name 'NoRecentDocsHistory' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hkcuPolicies -Name 'NoRemoteDestinations' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackProgs' -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackDocs' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Finished, features relating to app, document, etc tracking have been disabled.'
                }
            }
        }
        Unlock  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Unlock Recent Items\Unlock Recent Items.cmd'
            Reboot     = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerAndSettingsRefresh'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Write-Host 'Unlocking recent items...'

                $hklmExplorer = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hklmPolicies = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                Remove-AtlasRegistryValue -Path $hklmExplorer -Name 'NoStartMenuMFUprogramsList'
                Remove-AtlasRegistryValue -Path $hklmExplorer -Name 'NoRecentDocsHistory'
                Remove-AtlasRegistryValue -Path $hklmPolicies -Name 'ShowOrHideMostUsedApps'
                Remove-AtlasRegistryValue -Path $hklmPolicies -Name 'HideRecentlyAddedApps'

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages unhide privacy-general -Silent:$Toggle.Silent -NoProcessCleanup
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                $hkcuExplorer = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hkcuPolicies = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                Remove-AtlasRegistryValue -Path $hkcuExplorer -Name 'NoInstrumentation'
                Remove-AtlasRegistryValue -Path $hkcuExplorer -Name 'ClearRecentDocsOnExit'
                Remove-AtlasRegistryValue -Path $hkcuExplorer -Name 'NoRecentDocsHistory'
                Remove-AtlasRegistryValue -Path $hkcuPolicies -Name 'NoRemoteDestinations'

                $advanced = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                if (-not (Test-Path -LiteralPath $advanced)) { New-Item -Path $advanced -Force | Out-Null }
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackProgs' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackDocs' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Finished, you should be able to configure features relating to app, document, etc tracking.'
                    Write-Host "See File Explorer's options panel, as well as the Start and general privacy settings pages."
                }
            }
        }
    }
}
