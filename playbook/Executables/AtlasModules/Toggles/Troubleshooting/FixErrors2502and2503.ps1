# Toggle: Fix installer errors 2502 and 2503 by resetting the Windows TEMP folder permissions
# (no state recording).
@{
    Name          = 'FixErrors2502and2503'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher        = '9. Troubleshooting\Fix Errors 2502 and 2503.cmd'
            ToolboxLauncher = 'Scripts\Troubleshooting\Fix Errors 2502 and 2503.cmd'
            Reboot          = 'None'
            Action   = {
                param($Toggle)

                if (-not $Toggle.Silent) {
                    Write-Host 'This script will fix errors 2502 and 2503 with Windows installers by resetting the Windows TEMP folder permissions.'
                    Write-Host 'This issue is not related to Atlas.'
                }

                $helper = Join-Path -Path $Toggle.ScriptsPath `
                    -ChildPath 'Internal\Repair-AtlasWindowsTempPermissions.ps1'
                if (-not [IO.File]::Exists($helper)) {
                    throw "The Windows TEMP permission helper is missing at '$helper'."
                }

                Write-Host 'Repairing the Windows TEMP root permissions...'
                & $helper

                Write-Host 'Completed.'
            }
        }
    }
}
