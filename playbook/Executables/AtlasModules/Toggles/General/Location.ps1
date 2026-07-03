# Toggle: Location services (lfsvc / MapsBroker) and Find My Device.
#
# The Enable path's "Unlock Find My Device" prompt is interactive-only so silent/upgrade
# re-apply never hangs; in silent mode Find My Device is left disabled.
@{
    Name      = 'Location'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Location\Disable Location (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $sc = "$($Toggle.WinDir)\System32\sc.exe"
                & $sc config lfsvc start=disabled | Out-Null
                & $sc config MapsBroker start=disabled | Out-Null

                $findMyDevice = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
                if (-not (Test-Path -LiteralPath $findMyDevice)) { New-Item -Path $findMyDevice -Force | Out-Null }
                New-ItemProperty -LiteralPath $findMyDevice -Name 'AllowFindMyDevice' -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $findMyDevice -Name 'LocationSyncEnabled' -Value 0 -PropertyType DWord -Force | Out-Null

                $consent = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
                if (-not (Test-Path -LiteralPath $consent)) { New-Item -Path $consent -Force | Out-Null }
                New-ItemProperty -LiteralPath $consent -Name 'ShowGlobalPrompts' -Value 0 -PropertyType DWord -Force | Out-Null

                & $sc stop lfsvc 2>$null | Out-Null
                & $sc stop MapsBroker 2>$null | Out-Null

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages hide privacy-location -Silent
                & $settingsPages hide findmydevice -Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Location services have been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Location\Enable Location.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $sc = "$($Toggle.WinDir)\System32\sc.exe"
                & $sc config lfsvc start=demand | Out-Null
                & $sc config MapsBroker start=auto | Out-Null
                & $sc start lfsvc 2>$null | Out-Null
                & $sc start MapsBroker 2>$null | Out-Null

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-SettingsPageVisibility.ps1'
                & $settingsPages unhide privacy-location -Silent:$Toggle.Silent

                $findMyDevice = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
                if (-not $Toggle.Silent) {
                    $answer = Read-Host 'Would you like to unlock Find My Device functionality? [Y/N]'
                    if ($answer -match '^(y|yes)$') {
                        Remove-Item -LiteralPath $findMyDevice -Recurse -Force -ErrorAction SilentlyContinue
                        & $settingsPages unhide findmydevice -Silent
                    }
                    else {
                        if (-not (Test-Path -LiteralPath $findMyDevice)) { New-Item -Path $findMyDevice -Force | Out-Null }
                        New-ItemProperty -LiteralPath $findMyDevice -Name 'AllowFindMyDevice' -Value 0 -PropertyType DWord -Force | Out-Null
                        New-ItemProperty -LiteralPath $findMyDevice -Name 'LocationSyncEnabled' -Value 0 -PropertyType DWord -Force | Out-Null
                    }

                    Write-Host ''
                    Write-Host 'Location services have been enabled.'
                    Start-Process 'ms-settings:privacy-location'
                }
            }
        }
    }
}
