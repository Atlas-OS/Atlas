# Toggle: Modern vs old (Windows 8-style) volume flyout.
@{
    Name      = 'ModernVolumeFlyout'
    Elevation = 'Admin'
    States    = [ordered]@{
        Modern = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Old Flyouts\Volume Flyout\Modern Volume Flyout (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MTCUVC' -Name 'EnableMtcUvc'

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Old    = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Old Flyouts\Volume Flyout\Old Volume Flyout.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MTCUVC'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'EnableMtcUvc' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
