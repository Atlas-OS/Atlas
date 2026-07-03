# Toggle: CPU Idle (processor idle-disable power setting).
# Converted from 'AtlasDesktop\3. General Configuration\CPU Idle\*.cmd'.
#
# The powercfg processor setting is inverted relative to the toggle:
#   "Disable Idle" (state 0) sets the idle-disable value to 1 (idle off),
#   "Enable Idle"  (state 1) sets it to 0 (idle on).
# On Hyper-Threading/SMT systems the source refused to disable idle (it harms
# performance); this reproduces that guard by warning and leaving idle untouched.
# Deviation from the batch: the engine records the toggle state before the Action
# runs, so on an SMT machine the state is recorded but the powercfg value is left
# unchanged (the batch recorded nothing). Re-apply is self-correcting.
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
                    Write-AtlasLog -Level Warning -Message 'CpuIdle: SMT detected; idle states left enabled.'
                    return
                }

                if (-not $Toggle.Silent) {
                    Write-Host 'This forces your CPU to work at its maximum speed always; ensure you have good cooling.'
                    Write-Host 'Task Manager will show CPU usage as 100% always because of how it calculates the'
                    Write-Host 'percentage - other tools (Process Explorer, System Informer) report correctly.'
                }

                & $powercfg /setacvalueindex scheme_current sub_processor $idleGuid 1
                & $powercfg /setactive scheme_current
                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\CPU Idle\Enable Idle (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $powercfg = "$($Toggle.WinDir)\System32\powercfg.exe"
                & $powercfg /setacvalueindex scheme_current sub_processor '5d76a2ca-e8c0-402f-a133-2158492d58ad' 0
                & $powercfg /setactive scheme_current
                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
            }
        }
    }
}
