# Toggle: application icon overlays on File Explorer thumbnails.
@{
    Name      = 'AppIconThumbnail'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\App Icons on Thumbnails\Disable App Icons on Thumbnails.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTypeOverlay' -Type DWord -Data 0

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\App Icons on Thumbnails\Enable App Icons on Thumbnails (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTypeOverlay' -Type DWord -Data 1

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
