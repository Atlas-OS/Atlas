# Toggle: 'Take Ownership' context menu entries.
# Each state imports the matching verbatim .reg file via Atlas.Registry's Import-AtlasRegFile.
@{
    Name      = 'TakeOwnership'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Take Ownership\Remove Take Ownership to Context Menu (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\TakeOwnership\remove.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Context Menus\Take Ownership\Add Take Ownership to Context Menu.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue
                Import-AtlasRegFile -Path (Join-Path $Toggle.ScriptsPath 'Registry\TakeOwnership\add.reg')

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
