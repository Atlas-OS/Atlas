# Toggle: Pause Windows Updates (WindowsUpdate UX / UpdatePolicy pause dates).
#
# Pause also records a 'days' value under the AtlasOS\Services key, which some UI reads
# (the engine still records state/path separately).
@{
    Name      = 'PauseUpdates'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Pause   = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Pause Updates\Pause Windows Updates.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $svcKey = 'HKLM:\SOFTWARE\AtlasOS\Services\PauseUpdates'
                if (-not (Test-Path -LiteralPath $svcKey)) { New-Item -Path $svcKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $svcKey -Name 'days' -Value 356000 -PropertyType DWord -Force | Out-Null

                Write-Host 'Applying Windows Update pause policies...'

                $upKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
                if (-not (Test-Path -LiteralPath $upKey)) { New-Item -Path $upKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $upKey -Name 'PausedFeatureStatus' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $upKey -Name 'PausedQualityStatus' -Value 1 -PropertyType DWord -Force | Out-Null

                $uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
                if (-not (Test-Path -LiteralPath $uxKey)) { New-Item -Path $uxKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $uxKey -Name 'FlightSettingsMaxPauseDays' -Value 356000 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'PauseFeatureUpdatesStartTime' -Value '2001-10-25T10:03:37Z' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'PauseQualityUpdatesStartTime' -Value '2001-10-25T10:03:37Z' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'PauseUpdatesStartTime' -Value '2001-10-25T10:03:37Z' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'PauseFeatureUpdatesEndTime' -Value '3000-12-31T14:03:37Z' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'PauseQualityUpdatesEndTime' -Value '3000-12-31T14:03:37Z' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'PauseUpdatesExpiryTime' -Value '3000-12-31T14:03:37Z' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'HideMCTLink' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $uxKey -Name 'RestartNotificationsAllowed2' -Value 0 -PropertyType DWord -Force | Out-Null

                $upgKey = 'HKLM:\SYSTEM\Setup\UpgradeNotification'
                if (-not (Test-Path -LiteralPath $upgKey)) { New-Item -Path $upgKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $upgKey -Name 'UpgradeAvailable' -Value 0 -PropertyType DWord -Force | Out-Null

                Write-Host 'Done. Windows Updates have been paused.'
            }
        }
        Unpause = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Pause Updates\Unpause Windows Updates.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $svcKey = 'HKLM:\SOFTWARE\AtlasOS\Services\PauseUpdates'
                if (-not (Test-Path -LiteralPath $svcKey)) { New-Item -Path $svcKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $svcKey -Name 'days' -Value 0 -PropertyType DWord -Force | Out-Null

                Write-Host 'Resetting Windows Update pause policies...'

                $wuKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
                Remove-ItemProperty -LiteralPath $wuKey -Name 'DeferFeatureUpdates' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $wuKey -Name 'DeferFeatureUpdatesPeriodInDays' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $wuKey -Name 'DeferQualityUpdates' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $wuKey -Name 'DeferQualityUpdatesPeriodInDays' -Force -ErrorAction SilentlyContinue
                foreach ($k in @('Feature', 'Quality')) {
                    Remove-ItemProperty -LiteralPath $wuKey -Name "Pause${k}Updates" -Force -ErrorAction SilentlyContinue
                    Remove-ItemProperty -LiteralPath $wuKey -Name "Pause${k}UpdatesStartTime" -Force -ErrorAction SilentlyContinue
                }

                $upKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
                if (-not (Test-Path -LiteralPath $upKey)) { New-Item -Path $upKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $upKey -Name 'PausedFeatureStatus' -Value 0 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $upKey -Name 'PausedQualityStatus' -Value 0 -PropertyType DWord -Force | Out-Null

                $uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
                foreach ($v in @(
                        'PauseFeatureUpdatesStartTime', 'PauseFeatureUpdatesEndTime',
                        'PauseQualityUpdatesStartTime', 'PauseQualityUpdatesEndTime',
                        'PauseUpdatesStartTime', 'PauseUpdatesExpiryTime',
                        'PausedFeatureStatus', 'PausedQualityStatus', 'FlightSettingsMaxPauseDays',
                        'HideMCTLink', 'RestartNotificationsAllowed2')) {
                    Remove-ItemProperty -LiteralPath $uxKey -Name $v -Force -ErrorAction SilentlyContinue
                }

                Remove-ItemProperty -LiteralPath 'HKLM:\SYSTEM\Setup\UpgradeNotification' -Name 'UpgradeAvailable' -Force -ErrorAction SilentlyContinue

                Write-Host 'Done. Updates have been unpaused.'
            }
        }
    }
}
