# Toggle: Power-saving (documented Atlas AC policy vs. the prior power plan).
#
# Both states use the same internal implementation.
@{
    Name      = 'PowerSaving'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Power-saving\Disable Power-saving.cmd'
            Reboot     = 'None'
            ReplayScope = 'Machine'
            Action     = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath `
                    -ChildPath 'Internal\Set-PowerSavingState.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    throw "Required Power Saving helper is missing: '$script'."
                }
                & $script -Mode Atlas -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'The documented Atlas AC power policy has been applied.'
                }
            }
        }
        Default = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Power-saving\Default Power-saving (default).cmd'
            Reboot     = 'None'
            ReplayScope = 'Machine'
            Action     = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath `
                    -ChildPath 'Internal\Set-PowerSavingState.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    throw "Required Power Saving helper is missing: '$script'."
                }
                & $script -Mode Default -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'The prior installed power plan, or Balanced fallback, is active and the Atlas plan has been removed.'
                }
            }
        }
    }
}
