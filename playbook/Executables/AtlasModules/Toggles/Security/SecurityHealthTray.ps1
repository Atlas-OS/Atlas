# Toggle: Windows Security (Defender) tray icon startup entry.
# Converted from 'AtlasDesktop\7. Security\Defender\Security Health Tray\*.cmd'.
# Each state imports the matching verbatim .reg file via Atlas.Registry's Import-AtlasRegFile.
@{
    Name      = 'SecurityHealthTray'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '7. Security\Defender\Security Health Tray\Remove Security Tray from Startup (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\SecurityHealthTray\disable.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '7. Security\Defender\Security Health Tray\Add Security Tray to Startup.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\SecurityHealthTray\enable.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
