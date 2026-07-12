# Toggle: Network reset (Atlas adapter defaults vs. Windows defaults).
#
# Both states use the same implementation as the manual Toolbox launchers.
@{
    Name      = 'DefaultAtlasNetwork'
    Elevation = 'Admin'
    States    = [ordered]@{
        AtlasDefault   = @{
            StateValue  = 1
            ReplayScope = 'Machine'
            Launcher    = '9. Troubleshooting\Network\Reset Network to Atlas Default.cmd'
            Reboot      = 'Recommend'
            Action      = {
                param($Toggle)

                $helper = Join-Path -Path $Toggle.ScriptsPath `
                    -ChildPath 'Internal\Set-NetworkDefaults.ps1'
                if (-not [IO.File]::Exists($helper)) {
                    throw "The network-default helper is missing at '$helper'."
                }

                & $helper -Mode Atlas
                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, please reboot your device for changes to apply.'
                }
            }
        }
        WindowsDefault = @{
            StateValue  = 0
            ReplayScope = 'Machine'
            Launcher    = '9. Troubleshooting\Network\Reset Network to Windows Default.cmd'
            Reboot      = 'Recommend'
            Action      = {
                param($Toggle)

                $helper = Join-Path -Path $Toggle.ScriptsPath `
                    -ChildPath 'Internal\Set-NetworkDefaults.ps1'
                if (-not [IO.File]::Exists($helper)) {
                    throw "The network-default helper is missing at '$helper'."
                }

                & $helper -Mode Windows
                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, please reboot your device for changes to apply.'
                }
            }
        }
    }
}
