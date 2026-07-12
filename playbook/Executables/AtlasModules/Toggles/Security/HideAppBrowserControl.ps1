# Toggle: Hide/show the App and Browser Control page in Windows Security.
@{
    Name      = 'HideAppBrowserControl'
    Elevation = 'Admin'
    States    = [ordered]@{
        Hide = @{
            StateValue = 0
            ReplayScope = 'Machine'
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
            ReplayScope = 'Machine'
            Launcher   = '7. Security\Defender\Hide App and Browser Control\Show App and Browser Control.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection' -Name 'UILockdown'

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
