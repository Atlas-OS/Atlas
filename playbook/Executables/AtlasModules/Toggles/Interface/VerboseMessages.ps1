# Toggle: Verbose (detailed) startup/shutdown status messages.
# Converted from 'AtlasDesktop\4. Interface Tweaks\Verbose Status Messages\*.cmd'.
@{
    Name      = 'VerboseMessages'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Verbose Status Messages\Disable Verbose Messages (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'verbosestatus' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Verbose Status Messages\Enable Verbose Messages.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'verbosestatus' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
