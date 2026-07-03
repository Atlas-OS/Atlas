# Toggle: 'Terminals' context menu (removed / full / no Windows Terminal).
# Converted from 'AtlasDesktop\4. Interface Tweaks\Context Menus\Terminals\*.cmd'.
#
# One setting ('ContextMenuTerminals') with three launchers, each importing a verbatim .reg
# file: Remove=0 -> disabled.reg, Add=1 -> enabled.reg, AddNoWindowsTerminal=2 -> minimal.reg.
@{
    Name      = 'ContextMenuTerminals'
    Elevation = 'Admin'
    States    = [ordered]@{
        Remove               = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Terminals\Remove Terminals Context Menu (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\Terminals\disabled.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Add                  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Context Menus\Terminals\Add Terminals.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\Terminals\enabled.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        AddNoWindowsTerminal = @{
            StateValue = 2
            Launcher   = '4. Interface Tweaks\Context Menus\Terminals\Add Terminals (no Windows Terminal).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\Terminals\minimal.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
