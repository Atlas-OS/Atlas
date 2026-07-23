# Toggle: Modern vs old (Windows 8-style) battery flyout.
@{
    Name      = 'ModernBatteryFlyout'
    Elevation = 'Admin'
    States    = [ordered]@{
        Modern = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Old Flyouts\Battery Flyout\Modern Battery Flyout (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'UseWin32BatteryFlyout' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Old    = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Old Flyouts\Battery Flyout\Old Battery Flyout.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'UseWin32BatteryFlyout' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
