# Toggle: Power-saving (Atlas power scheme vs. default Windows schemes).
# Converted from 'AtlasDesktop\3. General Configuration\Power-saving\*.cmd'.
#
# The original launchers were thin wrappers that ran the ScriptWrappers\*PowerSaving.ps1
# scripts, which simply forward to the Internal\*PowerSaving.ps1 scripts. This definition
# calls the Internal scripts directly (their real implementation).
@{
    Name      = 'PowerSaving'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Power-saving\Disable Power-saving.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\DisablePowerSaving.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Power Saving has been disabled.'
                }
            }
        }
        Default = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Power-saving\Default Power-saving (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\DefaultPowerSaving.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Default Power Saving has been set to its default configuration.'
                }
            }
        }
    }
}
