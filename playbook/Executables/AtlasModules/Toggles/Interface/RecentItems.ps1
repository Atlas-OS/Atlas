# Toggle: Recent Items / app & document usage tracking.
# Converted from 'AtlasDesktop\4. Interface Tweaks\Unlock Recent Items\*.cmd'.
@{
    Name      = 'RecentItems'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Unlock Recent Items\Disable Recent Items (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Write-Host 'Disabling recent items...'

                $hkcuExplorer = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hkcuPolicies = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                $hklmExplorer = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hklmPolicies = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                $advanced = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                foreach ($key in @($hkcuExplorer, $hkcuPolicies, $hklmExplorer, $hklmPolicies, $advanced)) {
                    if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                }

                New-ItemProperty -LiteralPath $hkcuExplorer -Name 'NoInstrumentation' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hkcuExplorer -Name 'ClearRecentDocsOnExit' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hkcuExplorer -Name 'NoRecentDocsHistory' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hkcuPolicies -Name 'NoRemoteDestinations' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmExplorer -Name 'NoStartMenuMFUprogramsList' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmExplorer -Name 'NoRecentDocsHistory' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmPolicies -Name 'ShowOrHideMostUsedApps' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $hklmPolicies -Name 'HideRecentlyAddedApps' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackProgs' -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackDocs' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.NoExplorerRestart) {
                    & "$($Toggle.WinDir)\System32\taskkill.exe" /f /im explorer.exe 2>$null | Out-Null
                    & "$($Toggle.WinDir)\System32\taskkill.exe" /f /im SettingsApp.exe 2>$null | Out-Null
                    Start-Process 'explorer.exe'
                }

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages hide privacy-general -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Finished, features relating to app, document, etc tracking have been disabled.'
                }
            }
        }
        Unlock  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Unlock Recent Items\Unlock Recent Items.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Write-Host 'Unlocking recent items...'

                $hkcuExplorer = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hkcuPolicies = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                $hklmExplorer = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                $hklmPolicies = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
                Remove-ItemProperty -LiteralPath $hkcuExplorer -Name 'NoInstrumentation' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $hkcuExplorer -Name 'ClearRecentDocsOnExit' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $hkcuExplorer -Name 'NoRecentDocsHistory' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $hkcuPolicies -Name 'NoRemoteDestinations' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $hklmExplorer -Name 'NoStartMenuMFUprogramsList' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $hklmExplorer -Name 'NoRecentDocsHistory' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $hklmPolicies -Name 'ShowOrHideMostUsedApps' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $hklmPolicies -Name 'HideRecentlyAddedApps' -Force -ErrorAction SilentlyContinue

                $advanced = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                if (-not (Test-Path -LiteralPath $advanced)) { New-Item -Path $advanced -Force | Out-Null }
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackProgs' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $advanced -Name 'Start_TrackDocs' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.NoExplorerRestart) {
                    & "$($Toggle.WinDir)\System32\taskkill.exe" /f /im explorer.exe 2>$null | Out-Null
                    Start-Process 'explorer.exe'
                    & "$($Toggle.WinDir)\System32\taskkill.exe" /f /im SettingsApp.exe 2>$null | Out-Null
                }

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages unhide privacy-general -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Finished, you should be able to configure features relating to app, document, etc tracking.'
                    Write-Host "See File Explorer's options panel, as well as the Start and general privacy settings pages."
                }
            }
        }
    }
}
