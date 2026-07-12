# Toggle: Gallery item in the File Explorer navigation pane.
@{
    Name      = 'Gallery'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' -Name 'System.IsPinnedToNameSpaceTree' -Type DWord -Data 0

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Gallery\Enable Gallery.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' -Name 'System.IsPinnedToNameSpaceTree' -Type DWord -Data 1

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
