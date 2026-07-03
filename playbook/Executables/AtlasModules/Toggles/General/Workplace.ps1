# Toggle: Workplace (Access work or school) settings page visibility.
# Converted from 'AtlasDesktop\3. General Configuration\Workplace\*.cmd'.
#
# The original called serviceWarning.cmd (skipped under /silent); that is the engine's
# Warning surface. ms-settings:workplace is opened interactively only.
@{
    Name      = 'Workplace'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Workplace\Disable Workplace.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SettingsPages.ps1'
                & $settingsPages hide workplace -Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Workplace settings page has been hidden.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Workplace\Enable Workplace.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $settingsPages = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SettingsPages.ps1'
                & $settingsPages unhide workplace -Silent

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Workplace settings page has been restored.'
                    Start-Process 'ms-settings:workplace'
                }
            }
        }
    }
}
