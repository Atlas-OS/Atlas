# Toggle: Mobile Devices / Phone Link (CDPSvc, cross-device resume, YourPhone appx).
#
# The ms-settings:mobile-devices page is only opened interactively so upgrade re-apply
# stays headless.
@{
    Name      = 'PhoneLink'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Mobile Devices (Phone Link)\Disable Mobile Device Settings (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $system = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
                if (-not (Test-Path -LiteralPath $system)) { New-Item -Path $system -Force | Out-Null }
                New-ItemProperty -LiteralPath $system -Name 'NoConnectedUser' -Value 1 -PropertyType DWord -Force | Out-Null

                $resume = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
                if (-not (Test-Path -LiteralPath $resume)) { New-Item -Path $resume -Force | Out-Null }
                New-ItemProperty -LiteralPath $resume -Name 'IsResumeAllowed' -Value 0 -PropertyType DWord -Force | Out-Null

                $policyResume = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'
                if (-not (Test-Path -LiteralPath $policyResume)) { New-Item -Path $policyResume -Force | Out-Null }
                New-ItemProperty -LiteralPath $policyResume -Name 'Value' -Value 1 -PropertyType DWord -Force | Out-Null

                $cdp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP'
                if (-not (Test-Path -LiteralPath $cdp)) { New-Item -Path $cdp -Force | Out-Null }
                New-ItemProperty -LiteralPath $cdp -Name 'NearShareChannelUserAuthzPolicy' -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $cdp -Name 'CdpSessionUserAuthzPolicy' -Value 1 -PropertyType DWord -Force | Out-Null

                $cdpSettings = "$cdp\SettingsPage"
                if (-not (Test-Path -LiteralPath $cdpSettings)) { New-Item -Path $cdpSettings -Force | Out-Null }
                New-ItemProperty -LiteralPath $cdpSettings -Name 'BluetoothLastDisabledNearShare' -Value 0 -PropertyType DWord -Force | Out-Null

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages hide mobile-devices -Silent:$Toggle.Silent

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setSvc -Name 'CDPSvc' -Start 4

                & "$($Toggle.WinDir)\System32\taskkill.exe" /f /im RuntimeBroker.exe 2>$null | Out-Null
                & "$($Toggle.WinDir)\System32\taskkill.exe" /f /im PhoneExperienceHost.exe 2>$null | Out-Null
                Get-AppxPackage -AllUsers 'Microsoft.YourPhone*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq 'Microsoft.YourPhone' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null

                if ($Toggle.Silent) { return }

                $answer = Read-Host 'Would you like to attempt Phone Link removal again? [Y/N]'
                if ($answer -match '^(y|yes)$') {
                    Get-AppxPackage -AllUsers 'Microsoft.YourPhone*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                }

                $storeUpdate = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'
                if (-not (Test-Path -LiteralPath $storeUpdate)) { New-Item -Path $storeUpdate -Force | Out-Null }
                $answer = Read-Host 'Would you like to disable Store auto-updates? [Y/N]'
                if ($answer -match '^(y|yes)$') {
                    New-ItemProperty -LiteralPath $storeUpdate -Name 'AutoDownload' -Value 2 -PropertyType DWord -Force | Out-Null
                }
                else {
                    New-ItemProperty -LiteralPath $storeUpdate -Name 'AutoDownload' -Value 4 -PropertyType DWord -Force | Out-Null
                }

                Write-Host ''
                Write-Host 'Phone Link has been disabled.'
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Mobile Devices (Phone Link)\Enable Mobile Device Settings.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'NoConnectedUser' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Force -ErrorAction SilentlyContinue

                $resume = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
                if (-not (Test-Path -LiteralPath $resume)) { New-Item -Path $resume -Force | Out-Null }
                New-ItemProperty -LiteralPath $resume -Name 'IsResumeAllowed' -Value 1 -PropertyType DWord -Force | Out-Null

                $policyResume = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'
                if (-not (Test-Path -LiteralPath $policyResume)) { New-Item -Path $policyResume -Force | Out-Null }
                New-ItemProperty -LiteralPath $policyResume -Name 'Value' -Value 0 -PropertyType DWord -Force | Out-Null

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setSvc -Name 'CDPSvc' -Start 3

                $storeUpdate = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'
                if (-not (Test-Path -LiteralPath $storeUpdate)) { New-Item -Path $storeUpdate -Force | Out-Null }
                New-ItemProperty -LiteralPath $storeUpdate -Name 'AutoDownload' -Value 4 -PropertyType DWord -Force | Out-Null

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages unhide mobile-devices -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Start-Process 'ms-settings:mobile-devices'
                    Write-Host ''
                    Write-Host 'Phone Link has been enabled. You can now sync your phone.'
                }
            }
        }
    }
}
