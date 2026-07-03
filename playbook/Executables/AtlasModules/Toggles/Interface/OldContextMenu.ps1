# Toggle: Windows 11 file context menu (old full menu vs new compact menu).
# Converted from 'AtlasDesktop\4. Interface Tweaks\Context Menus\Windows 11\*.cmd'.
@{
    Name      = 'OldContextMenu'
    Elevation = 'Admin'
    States    = [ordered]@{
        Old = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                New-AtlasRegistryKey -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        New = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Windows 11\New Context Menu.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction SilentlyContinue

                Remove-AtlasRegistryKey -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
