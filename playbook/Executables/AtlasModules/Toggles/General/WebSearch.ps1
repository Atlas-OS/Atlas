# Toggle: Web Search / Search Highlights.
#
# Explorer/SearchHost are restarted unless the launcher was called with /noAction
# (engine -NoExplorerRestart). HKCU writes run only in the bound non-elevated caller.
# Enable installs the Bing search provider via winget and, with search indexing
# stopped, offers to enable indexing (a graphical-bug fix).
@{
    Name      = 'WebSearch'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Web Search (includes Search Highlights)\Disable Web Search (default).cmd'
            Reboot     = 'RestartExplorer'
            ShellRefreshOperation = 'SearchShellRefresh'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
                        -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
                    -ErrorAction Stop
                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
                        -ChildPath 'Modules\Atlas.Appx\Atlas.Appx.psd1') `
                    -ErrorAction Stop

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages hide search-permissions -Silent -NoProcessCleanup
                $windowsSearchPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
                Set-AtlasRegistryValue -Path $windowsSearchPolicy `
                    -Name 'AllowSearchToUseLocation' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path $windowsSearchPolicy `
                    -Name 'ConnectedSearchUseWeb' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path $windowsSearchPolicy `
                    -Name 'DisableWebSearch' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path $windowsSearchPolicy `
                    -Name 'EnableDynamicContentInWSB' -Type DWord -Data 0
                Set-AtlasRegistryValue `
                    -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' `
                    -Name 'DisableSearchBoxSuggestions' -Type DWord -Data 1

                Invoke-AtlasAppxRemovalPlan -Definition @(
                    [pscustomobject]@{
                        Name         = 'Microsoft.BingSearch*'
                        Option       = $null
                        IgnoreErrors = $false
                    }
                )
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
                        -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
                    -ErrorAction Stop

                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' `
                    -Name 'BingSearchEnabled' -Type DWord -Data 0
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' `
                    -Name 'IsAADCloudSearchEnabled' -Type DWord -Data 0
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' `
                    -Name 'IsDeviceSearchHistoryEnabled' -Type DWord -Data 0
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' `
                    -Name 'IsMSACloudSearchEnabled' -Type DWord -Data 0
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' `
                    -Name 'SafeSearchMode' -Type DWord -Data 0
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' `
                    -Name 'SearchboxTaskbarMode' -Type DWord -Data 1
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' `
                    -Name 'IsDynamicSearchBoxEnabled' -Type DWord -Data 0
                if (-not $Toggle.Silent) { Write-Host 'Web Search has been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Web Search (includes Search Highlights)\Enable Web Search.cmd'
            Reboot     = 'RestartExplorer'
            ShellRefreshOperation = 'SearchShellRefresh'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                Write-Host 'Enabling Web Search & Search Highlights...'

                $locationKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
                $useLocation = $true
                if (-not $Toggle.Silent) {
                    $answer = Read-Host 'Would you like web search to use your location for results? [Y/N]'
                    $useLocation = ($answer -match '^(y|yes)$')
                }
                if ($useLocation) {
                    Remove-AtlasRegistryValue -Path $locationKey -Name 'AllowSearchToUseLocation'
                }
                else {
                    Set-AtlasRegistryValue -Path $locationKey `
                        -Name 'AllowSearchToUseLocation' -Type DWord -Data 0
                }

                # Stopped search indexing shows a graphical bug in web search.
                $wsearch = Get-Service -Name wsearch -ErrorAction Stop
                if ($wsearch.Status -eq 'Stopped') {
                    $enableIndexing = $true
                    if (-not $Toggle.Silent) {
                        Write-Host 'Disabled search indexing causes a graphical bug in web search.'
                        $answer = Read-Host 'Would you like to enable search indexing to fix it? [Y/N]'
                        $enableIndexing = ($answer -match '^(y|yes)$')
                    }
                    if ($enableIndexing) {
                        $indexingMachineState = Join-Path $Toggle.ScriptsPath `
                            'Internal\Set-AtlasIndexingMachineState.ps1'
                        & $indexingMachineState -State Full
                    }
                }

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages unhide search-permissions -Silent -NoProcessCleanup

                foreach ($v in @(
                    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'ConnectedSearchUseWeb' }
                    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'DisableWebSearch' }
                    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'EnableDynamicContentInWSB' }
                    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions' }
                )) {
                    Remove-AtlasRegistryValue -Path $v.Path -Name $v.Name
                }
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                . (Join-Path $Toggle.ScriptsPath 'Internal\Initialize-PowerShellTrust.ps1')
                . (Join-Path $Toggle.ScriptsPath 'Internal\Download-Integrity.ps1')
                $wingetPath = Get-AtlasTrustedWingetPath
                Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
                [void](Invoke-AtlasToggleNativeCommand `
                        -FilePath $wingetPath `
                        -ArgumentList @(
                            'install'
                            '--exact'
                            '--id'
                            '9NZBF4GT040C'
                            '--source'
                            'msstore'
                            '--uninstall-previous'
                            '--silent'
                            '--accept-source-agreements'
                            '--accept-package-agreements'
                            '--disable-interactivity'
                        ) `
                        -AllowedExitCodes @(0))
                foreach ($v in @(
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsAADCloudSearchEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDeviceSearchHistoryEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsMSACloudSearchEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'SafeSearchMode' }
                )) {
                    Remove-AtlasRegistryValue -Path $v.Path -Name $v.Name
                }
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' `
                    -Name 'IsDynamicSearchBoxEnabled' -Type DWord -Data 1
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' `
                    -Name 'SearchboxTaskbarMode' -Type DWord -Data 2

                if (-not $Toggle.Silent) { Write-Host 'Finished, you should be able to use Web Search and Search Highlights.' }
            }
        }
    }
}
