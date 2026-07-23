# Toggle: 'Take Ownership' context menu entries.
@{
    Name      = 'TakeOwnership'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Context Menus\Take Ownership\Remove Take Ownership to Context Menu (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\TakeOwnership\remove.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Context Menus\Take Ownership\Add Take Ownership to Context Menu.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\TakeOwnership\add.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
