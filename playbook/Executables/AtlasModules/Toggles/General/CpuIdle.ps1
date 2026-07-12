# Toggle: CPU Idle (processor idle-disable power setting).
#
# The powercfg processor setting is inverted relative to the toggle:
#   "Disable Idle" (state 0) sets the idle-disable value to 1 (idle off),
#   "Enable Idle"  (state 1) sets it to 0 (idle on).
# On Hyper-Threading/SMT systems disabling idle harms performance, so the action
# rejects the transition without changing or recording the requested state.
@{
    Name      = 'CpuIdle'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\CPU Idle\Disable Idle.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $powercfg = "$($Toggle.WinDir)\System32\powercfg.exe"
                $idleGuid = '5d76a2ca-e8c0-402f-a133-2158492d58ad'

                $smt = $false
                foreach ($cpu in Get-CimInstance Win32_Processor) {
                    if ([int]$cpu.NumberOfLogicalProcessors -gt [int]$cpu.NumberOfCores) {
                        $smt = $true
                        break
                    }
                }

                if ($smt) {
                    if (-not $Toggle.Silent) {
                        Write-Host ''
                        Write-Host 'Hyper Threading / SMT detected.' -ForegroundColor Yellow
                        Write-Host 'You should not disable idle states while SMT is enabled - it makes'
                        Write-Host 'overall CPU performance much worse. Consider disabling C-states in BIOS'
                        Write-Host 'instead. No changes were made.'
                    }
                    throw 'CpuIdle cannot disable processor idle while Hyper-Threading or SMT is enabled; no changes were made.'
                }

                if (-not $Toggle.Silent) {
                    Write-Host 'This forces your CPU to work at its maximum speed always; ensure you have good cooling.'
                    Write-Host 'Task Manager will show CPU usage as 100% always because of how it calculates the'
                    Write-Host 'percentage - other tools (Process Explorer, System Informer) report correctly.'
                }

                Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
                    -ArgumentList ([string[]]@('/setacvalueindex', 'scheme_current', 'sub_processor', $idleGuid, '1')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
                Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
                    -ArgumentList ([string[]]@('/setactive', 'scheme_current')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\CPU Idle\Enable Idle (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $powercfg = "$($Toggle.WinDir)\System32\powercfg.exe"
                Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
                    -ArgumentList ([string[]]@('/setacvalueindex', 'scheme_current', 'sub_processor', '5d76a2ca-e8c0-402f-a133-2158492d58ad', '0')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
                Invoke-AtlasToggleNativeCommand -FilePath $powercfg `
                    -ArgumentList ([string[]]@('/setactive', 'scheme_current')) `
                    -AllowedExitCodes ([int[]]@(0)) | Out-Null
                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
            }
        }
    }
}
