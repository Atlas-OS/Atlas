# Toggle: Quick Access in File Explorer (HubMode hides it).
@{
    Name      = 'QuickAccess'
    Elevation = 'Admin'
    States    = [ordered]@{
        Remove = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Quick Access\Remove Quick Access.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'HubMode' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Show   = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Quick Access\Show Quick Access (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'HubMode'

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
