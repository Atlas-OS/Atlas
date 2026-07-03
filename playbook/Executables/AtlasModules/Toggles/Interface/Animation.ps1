# Toggle: Visual effects / animations (Atlas minimal set vs Windows defaults).
@{
    Name      = 'Animation'
    Elevation = 'Admin'
    States    = [ordered]@{
        Atlas   = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Visual Effects (Animations)\Atlas Visual Effects (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'FontSmoothing' -Type String -Data '2'
                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Type Binary -Data ([byte[]]@(0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00))
                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows' -Type String -Data '1'
                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Type String -Data '0'
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewAlphaSelect' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'IconsOnly' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewShadow' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Type DWord -Data 3
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Name 'EnableAeroPeek' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Name 'AlwaysHibernateThumbnails' -Type DWord -Data 0

                if (-not $Toggle.Silent) {
                    $answer = Read-Host 'Finished, would you like to logout to apply the changes? [Y/N]'
                    if ($answer -match '^[Yy]') {
                        & "$($Toggle.WinDir)\System32\logoff.exe"
                    }
                }
            }
        }
        Default = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Visual Effects (Animations)\Default Windows Visual Effects.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'FontSmoothing' -Type String -Data '2'
                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Type Binary -Data ([byte[]]@(0x9E, 0x1E, 0x07, 0x80, 0x12, 0x00, 0x00, 0x00))
                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows' -Type String -Data '1'
                Set-AtlasRegistryValue -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Type String -Data '1'
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewAlphaSelect' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'IconsOnly' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewShadow' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Type DWord -Data 0
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Name 'EnableAeroPeek' -Type DWord -Data 1
                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Name 'AlwaysHibernateThumbnails' -Type DWord -Data 1

                if (-not $Toggle.Silent) {
                    $answer = Read-Host 'Finished, would you like to logout to apply the changes? [Y/N]'
                    if ($answer -match '^[Yy]') {
                        & "$($Toggle.WinDir)\System32\logoff.exe"
                    }
                }
            }
        }
    }
}
