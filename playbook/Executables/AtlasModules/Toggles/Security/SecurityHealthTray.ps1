# Toggle: Windows Security (Defender) tray icon startup entry.
@{
    Name      = 'SecurityHealthTray'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '7. Security\Defender\Security Health Tray\Remove Security Tray from Startup (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\SecurityHealthTray\disable.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '7. Security\Defender\Security Health Tray\Add Security Tray to Startup.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\SecurityHealthTray\enable.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
