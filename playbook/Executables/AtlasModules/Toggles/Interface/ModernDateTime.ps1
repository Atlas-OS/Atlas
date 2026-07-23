# Toggle: Modern vs old (Windows 8-style) date/time (tray clock) flyout.
@{
    Name      = 'ModernDateTime'
    Elevation = 'Admin'
    States    = [ordered]@{
        Modern = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Old Flyouts\Date and Time Flyout\Modern Date and Time Flyout (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'UseWin32TrayClockExperience' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Old    = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Old Flyouts\Date and Time Flyout\Old Date and Time Flyout.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'UseWin32TrayClockExperience' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
