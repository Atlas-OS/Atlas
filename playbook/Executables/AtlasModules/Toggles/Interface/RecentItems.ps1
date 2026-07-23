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
                New-ItemProperty -LiteralPath $hklmExplorer -Name 'NoInstrumentation' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmExplorer -Name 'ClearRecentDocsOnExit' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmExplorer -Name 'NoRecentDocsHistory' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmPolicies -Name 'ShowOrHideMostUsedApps' -Value 2 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmPolicies -Name 'HideRecentlyAddedApps' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmPolicies -Name 'NoRemoteDestinations' -Value 1 -PropertyType DWord -Force | Out-Null

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages hide privacy-general -Silent:$Toggle.Silent -NoProcessCleanup
            }
            UserAction = {
                param($Toggle)

                $advanced = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                if (-not (Test-Path -LiteralPath $advanced)) { New-Item -Path $advanced -Force | Out-Null }
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

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                Write-Host 'Unlocking recent items...'

                $hklmExplorer = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hklmPolicies = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                Remove-AtlasRegistryValue -Path $hklmExplorer -Name 'NoStartMenuMFUprogramsList'
                Remove-AtlasRegistryValue -Path $hklmExplorer -Name 'NoInstrumentation'
                Remove-AtlasRegistryValue -Path $hklmExplorer -Name 'ClearRecentDocsOnExit'
                Remove-AtlasRegistryValue -Path $hklmExplorer -Name 'NoRecentDocsHistory'
                Remove-AtlasRegistryValue -Path $hklmPolicies -Name 'ShowOrHideMostUsedApps'
                Remove-AtlasRegistryValue -Path $hklmPolicies -Name 'HideRecentlyAddedApps'
                Remove-AtlasRegistryValue -Path $hklmPolicies -Name 'NoRemoteDestinations'

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages unhide privacy-general -Silent:$Toggle.Silent -NoProcessCleanup
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

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
