# Toggle: Extract entry in the file context menu (unblocks the archive shell extensions).
@{
    Name      = 'ExtractContextMenu'
    Elevation = 'Admin'
    States    = [ordered]@{
        Add    = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Context Menus\Extract\Add Extract.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
                foreach ($guid in @(
                        '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}',
                        '{BD472F60-27FA-11cf-B8B4-444553540000}',
                        '{EE07CEF5-3441-4CFB-870A-4002C724783A}',
                        '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}')) {
                    Remove-AtlasRegistryValue -Path $key -Name $guid
                }

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Remove = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Context Menus\Extract\Remove Extract (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                foreach ($guid in @(
                        '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}',
                        '{BD472F60-27FA-11cf-B8B4-444553540000}',
                        '{EE07CEF5-3441-4CFB-870A-4002C724783A}',
                        '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}')) {
                    New-ItemProperty -LiteralPath $key -Name $guid -Value '' -PropertyType String -Force | Out-Null
                }

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
