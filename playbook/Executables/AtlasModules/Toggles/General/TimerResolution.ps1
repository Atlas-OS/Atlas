# Toggle: Global timer resolution (scheduled task that forces a high timer resolution).
#
# The scheduled task is (re)created from the shipped XML at
# AtlasModules\Other\Force Timer Resolution.xml.
@{
    Name          = 'TimerResolution'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Warning       = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States        = [ordered]@{
        Disable = @{
            Launcher = '3. General Configuration\Timer Resolution\Disable timer resolution (default).cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name 'GlobalTimerResolutionRequests' -Force -ErrorAction SilentlyContinue
                Stop-Process -Name 'SetTimerResolution' -Force -ErrorAction SilentlyContinue
                & "$($Toggle.WinDir)\System32\schtasks.exe" /delete /tn 'Force Timer Resolution' /f 2>$null | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, changes have been applied.'
                }
            }
        }
        Enable  = @{
            Launcher = '3. General Configuration\Timer Resolution\Enable timer resolution.cmd'
            Reboot   = 'Recommend'
            Action   = {
                param($Toggle)

                New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name 'GlobalTimerResolutionRequests' -Value 1 -PropertyType DWord -Force | Out-Null

                $taskXml = Join-Path -Path $Toggle.AtlasModulesPath -ChildPath 'Other\Force Timer Resolution.xml'
                & "$($Toggle.WinDir)\System32\schtasks.exe" /create /tn 'Force Timer Resolution' /xml "$taskXml" /f | Out-Null
                & "$($Toggle.WinDir)\System32\schtasks.exe" /run /tn 'Force Timer Resolution' | Out-Null
            }
        }
    }
}
