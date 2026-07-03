# Toggle: Hide/show the App and Browser Control page in Windows Security.
# Converted from 'AtlasDesktop\7. Security\Defender\Hide App and Browser Control\*.cmd'.
@{
    Name      = 'HideAppBrowserControl'
    Elevation = 'Admin'
    States    = [ordered]@{
        Hide = @{
            StateValue = 0
            Launcher   = '7. Security\Defender\Hide App and Browser Control\Hide App and Browser Control (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'UILockdown' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Show = @{
            StateValue = 1
            Launcher   = '7. Security\Defender\Hide App and Browser Control\Show App and Browser Control.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection' -Name 'UILockdown' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
