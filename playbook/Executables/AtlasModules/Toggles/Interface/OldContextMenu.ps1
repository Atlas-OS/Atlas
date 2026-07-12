# Toggle: Windows 11 file context menu (old full menu vs new compact menu).
@{
    Name      = 'OldContextMenu'
    Elevation = 'Admin'
    States    = [ordered]@{
        Old = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                # The old menu only activates when the InprocServer32 DEFAULT value is
                # an empty string; a bare key ('value not set') leaves the modern menu.
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Name '' -Type String -Data ''

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        New = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Context Menus\Windows 11\New Context Menu.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

                Remove-AtlasRegistryKey -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
