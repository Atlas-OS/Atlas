# Toggle: Removable drives in the File Explorer navigation pane.
# Converted from 'AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Removable
# Drives in Sidebar\*.cmd'.
#
# Source-bug note: the Enable launcher wrote the DelegateFolders default value with
# '/t REG_DWORD /d "Removable Drives"', which reg.exe rejects (invalid DWORD data) so the
# original Enable was effectively a no-op. The corrected, working REG_SZ default value is
# written here (the value Windows expects to surface removable drives in the sidebar).
@{
    Name      = 'RemovableDrivesInSidebar'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Removable Drives in Sidebar\Disable Removable Drives in Sidebar (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-Item -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}' -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}' -Recurse -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\File Explorer Customization\Removable Drives in Sidebar\Enable Removable Drives in Sidebar.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                foreach ($key in @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'
                )) {
                    if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                    New-ItemProperty -LiteralPath $key -Name '(default)' -Value 'Removable Drives' -PropertyType String -Force | Out-Null
                }

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
