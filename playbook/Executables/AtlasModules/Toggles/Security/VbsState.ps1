# Toggle: documented Virtualization-Based Security and memory-integrity configuration.
@{
    Name      = 'VbsState'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue  = 0
            ReplayScope = 'Machine'
            Launcher    = '7. Security\Core Isolation (VBS)\Disable VBS.cmd'
            Reboot      = 'Recommend'
            Action      = {
                param($Toggle)

                $helper = Join-Path -Path $Toggle.ScriptsPath `
                    -ChildPath 'Internal\Set-VbsConfiguration.ps1'
                if (-not [IO.File]::Exists($helper)) {
                    throw "Required VBS configuration helper is missing at '$helper'."
                }
                & $helper -State Disable
            }
        }
        Enable = @{
            StateValue  = 1
            ReplayScope = 'Machine'
            Launcher    = '7. Security\Core Isolation (VBS)\Enable VBS.cmd'
            Reboot      = 'Recommend'
            Action      = {
                param($Toggle)

                $helper = Join-Path -Path $Toggle.ScriptsPath `
                    -ChildPath 'Internal\Set-VbsConfiguration.ps1'
                if (-not [IO.File]::Exists($helper)) {
                    throw "Required VBS configuration helper is missing at '$helper'."
                }
                & $helper -State Enable
            }
        }
    }
}
