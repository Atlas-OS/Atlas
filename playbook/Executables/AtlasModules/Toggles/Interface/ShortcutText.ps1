# Toggle: " - Shortcut" text suffix on newly created shortcuts.
@{
    Name      = 'ShortcutText'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Shortcut Text\Disable Shortcut Text (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' -Name 'ShortcutNameTemplate' -Type String -Data '"%s.lnk"'

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Restore = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Shortcut Text\Restore Shortcut Text.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Remove-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' -Name 'ShortcutNameTemplate'

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
