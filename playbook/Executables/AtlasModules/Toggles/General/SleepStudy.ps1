# Toggle: Sleep Study diagnostic event logs and the Power Efficiency Diagnostics task.
@{
    Name      = 'SleepStudy'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Sleep Study\Disable Sleep Study (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $wevtutil = "$($Toggle.WinDir)\System32\wevtutil.exe"
                foreach ($log in @(
                    'Microsoft-Windows-SleepStudy/Diagnostic'
                    'Microsoft-Windows-Kernel-Processor-Power/Diagnostic'
                    'Microsoft-Windows-UserModePowerService/Diagnostic'
                )) {
                    & $wevtutil sl "$log" /q:false | Out-Null
                }

                & "$($Toggle.WinDir)\System32\schtasks.exe" /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Sleep Study has been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Sleep Study\Enable Sleep Study.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $wevtutil = "$($Toggle.WinDir)\System32\wevtutil.exe"
                foreach ($log in @(
                    'Microsoft-Windows-SleepStudy/Diagnostic'
                    'Microsoft-Windows-Kernel-Processor-Power/Diagnostic'
                    'Microsoft-Windows-UserModePowerService/Diagnostic'
                )) {
                    & $wevtutil sl "$log" /q:true | Out-Null
                }

                & "$($Toggle.WinDir)\System32\schtasks.exe" /change /tn "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /enable | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Sleep Study has been enabled.'
                }
            }
        }
    }
}
