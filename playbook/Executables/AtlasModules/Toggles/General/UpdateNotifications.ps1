# Toggle: Windows Update restart notifications.
@{
    Name      = 'UpdateNotifications'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Update Notifications\Disable Update Notifications.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
                if (-not (Test-Path -LiteralPath $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $policyKey -Name 'SetAutoRestartNotificationDisable' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $policyKey -Name 'SetUpdateNotificationLevel' -Value 2 -PropertyType DWord -Force | Out-Null

                $uxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
                if (-not (Test-Path -LiteralPath $uxKey)) { New-Item -Path $uxKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $uxKey -Name 'RestartNotificationsAllowed2' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Update Notifications have been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Update Notifications\Enable Update Notifications (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'SetAutoRestartNotificationDisable' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'RestartNotificationsAllowed2' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'SetUpdateNotificationLevel' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Update Notifications have been enabled.'
                }
            }
        }
    }
}
