# Toggle: Quick Access in File Explorer (HubMode hides it).
# Converted from 'AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Quick Access\*.cmd'.
@{
    Name      = 'QuickAccess'
    Elevation = 'Admin'
    States    = [ordered]@{
        Remove = @{
            StateValue = 0
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
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Quick Access\Show Quick Access (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'HubMode' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
