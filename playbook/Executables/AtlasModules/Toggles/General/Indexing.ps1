# Toggle: Windows Search Indexing (disabled / minimal / full).
#
# Each state delegates the machine work to the installed indexing helper. Manual
# invocation and upgrade replay use the same TrustedInstaller action.

@{
    Name      = 'Indexing'
    Elevation = 'TrustedInstaller'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Search Indexing\Disable Search Indexing.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $machineStateHelper = Join-Path $Toggle.ScriptsPath `
                    'Internal\Set-AtlasIndexingMachineState.ps1'

                Write-Host ''
                Write-Host 'Disabling search indexing...'
                & $machineStateHelper -State Disable

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Search Indexing has been disabled.'
                }
            }
        }
        Minimal = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Search Indexing\Minimal Search Indexing (default).cmd'
            Reboot     = 'None'
            ReplayScope = 'Machine'
            Action     = {
                param($Toggle)

                $machineStateHelper = Join-Path $Toggle.ScriptsPath `
                    'Internal\Set-AtlasIndexingMachineState.ps1'

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Configuring minimal search indexing...'
                }
                & $machineStateHelper -State Minimal

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Minimal Search Indexing has been configured.'
                }
            }
        }
        Enable  = @{
            StateValue = 2
            Launcher   = '3. General Configuration\Search Indexing\Enable Search Indexing.cmd'
            Reboot     = 'None'
            ReplayScope = 'Machine'
            Action     = {
                param($Toggle)

                Write-Host ''
                Write-Host 'Enabling full search indexing...'
                $machineStateHelper = Join-Path $Toggle.ScriptsPath `
                    'Internal\Set-AtlasIndexingMachineState.ps1'
                $respectPowerModes = 0
                if (-not $Toggle.Silent) {
                    Write-Host ''
                    $answer = Read-Host 'Would you like to have indexing disable itself when on battery or gaming? [Y/N]'
                    if ($answer -match '^(y|yes)$') {
                        $respectPowerModes = 1
                    }
                }
                & $machineStateHelper `
                    -State Full `
                    -RespectPowerModes $respectPowerModes

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Full Search Indexing has been enabled.'
                }
            }
        }
    }
}
