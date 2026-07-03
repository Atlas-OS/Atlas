# Toggle: Shortcut overlay icon (default arrow / classic arrow / none).
@{
    Name      = 'ShortcutIcon'
    Elevation = 'Admin'
    States    = [ordered]@{
        Default = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Shortcut Icon\Default Windows (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons' -Name '29' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Classic = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Shortcut Icon\Classic.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name '29' -Value 'C:\Windows\AtlasModules\Other\Classic.ico,0' -PropertyType String -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        None    = @{
            StateValue = 2
            Launcher   = '4. Interface Tweaks\Shortcut Icon\None (security risk).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name '29' -Value 'C:\Windows\AtlasModules\Other\Blank.ico,0' -PropertyType String -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
