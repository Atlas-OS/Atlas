# Toggle: Snap Layouts / Snap Assist flyout and bar.
# Converted from 'AtlasDesktop\4. Interface Tweaks\Snap Layouts\*.cmd'.
@{
    Name      = 'SnapLayouts'
    Elevation = 'Admin'
    States    = [ordered]@{
        Enable  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Snap Layouts\Enable Snap Layouts (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'EnableSnapAssistFlyout' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'EnableSnapBar' -Type DWord -Data 1

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Snap Layouts\Disable Snap Layouts.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'EnableSnapAssistFlyout' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'EnableSnapBar' -Type DWord -Data 0

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
