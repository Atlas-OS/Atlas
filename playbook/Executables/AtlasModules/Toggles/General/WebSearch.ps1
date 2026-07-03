# Toggle: Web Search / Search Highlights.
# Converted from 'AtlasDesktop\3. General Configuration\Web Search (includes Search Highlights)\*.cmd'.
#
# Explorer/SearchHost are restarted unless the launcher was called with /noAction
# (engine -NoExplorerRestart). HKCU writes run as the interactive elevated user, matching
# the source's `reg add HKCU`. Enable installs the Bing search provider via winget and, on
# Windows 11 with search indexing stopped, offers to enable indexing (a graphical-bug fix).
@{
    Name      = 'WebSearch'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Web Search (includes Search Highlights)\Disable Web Search (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SettingsPages.ps1'
                & $settingsPages hide search-permissions -Silent

                Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowSearchToUseLocation' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsAADCloudSearchEnabled' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDeviceSearchHistoryEnabled' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsMSACloudSearchEnabled' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'SafeSearchMode' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWeb' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'DisableWebSearch' -Value 1 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord -Force
                Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'EnableDynamicContentInWSB' -Value 0 -Type DWord -Force
                Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Value 0 -Type DWord -Force

                if (-not $Toggle.NoExplorerRestart) {
                    Stop-Process -Name SearchHost -Force -ErrorAction SilentlyContinue
                    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                    Start-Process explorer.exe
                }
                Get-AppxPackage -AllUsers Microsoft.BingSearch* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) { Write-Host 'Web Search has been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Web Search (includes Search Highlights)\Enable Web Search.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $wingetCheck = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'wingetCheck.cmd'
                & "$env:ComSpec" /c "call `"$wingetCheck`""
                if ($LASTEXITCODE -ne 0) {
                    Write-AtlasLog -Level Warning -Message 'WebSearch: winget is not functional; cannot enable web search.'
                    return
                }

                Write-Host 'Enabling Web Search & Search Highlights...'

                $locationKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
                $useLocation = $true
                if (-not $Toggle.Silent) {
                    $answer = Read-Host 'Would you like web search to use your location for results? [Y/N]'
                    $useLocation = ($answer -match '^(y|yes)$')
                }
                if ($useLocation) {
                    Remove-ItemProperty -LiteralPath $locationKey -Name 'AllowSearchToUseLocation' -Force -ErrorAction SilentlyContinue
                }
                else {
                    Set-ItemProperty -LiteralPath $locationKey -Name 'AllowSearchToUseLocation' -Value 0 -Type DWord -Force
                }

                # Windows 11 with search indexing stopped shows a graphical bug in web search.
                if ($Toggle.WindowsBuild -ge 22000) {
                    $wsearch = Get-Service -Name wsearch -ErrorAction SilentlyContinue
                    if ($wsearch -and $wsearch.Status -eq 'Stopped') {
                        $enableIndexing = $true
                        if (-not $Toggle.Silent) {
                            Write-Host 'On Windows 11, disabled search indexing causes a graphical bug in web search.'
                            $answer = Read-Host 'Would you like to enable search indexing to fix it? [Y/N]'
                            $enableIndexing = ($answer -match '^(y|yes)$')
                        }
                        if ($enableIndexing) {
                            Invoke-AtlasToggle -Name 'Indexing' -State 'Enable' -Silent
                        }
                    }
                }

                Write-Host 'Installing the Bing search provider...'
                winget install -e --id 9NZBF4GT040C --uninstall-previous -h --accept-source-agreements --accept-package-agreements --force --disable-interactivity | Out-Null

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SettingsPages.ps1'
                & $settingsPages unhide search-permissions -Silent

                foreach ($v in @(
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsAADCloudSearchEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsDeviceSearchHistoryEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'IsMSACloudSearchEnabled' }
                    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name = 'SafeSearchMode' }
                    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'ConnectedSearchUseWeb' }
                    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'DisableWebSearch' }
                    @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions' }
                    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'EnableDynamicContentInWSB' }
                )) {
                    Remove-ItemProperty -LiteralPath $v.Path -Name $v.Name -Force -ErrorAction SilentlyContinue
                }
                Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Value 1 -Type DWord -Force
                Set-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 2 -Type DWord -Force

                if (-not $Toggle.NoExplorerRestart) {
                    Stop-Process -Name SearchHost -Force -ErrorAction SilentlyContinue
                    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                    Start-Process explorer.exe
                }

                if (-not $Toggle.Silent) { Write-Host 'Finished, you should be able to use Web Search and Search Highlights.' }
            }
        }
    }
}
