# Toggle: Home item in the File Explorer navigation pane (and its default launch target).
@{
    Name      = 'Home'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Home\Disable Home (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryKey -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Type DWord -Data 1

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Home\Enable Home.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Set-AtlasRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Type DWord -Data 0

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
