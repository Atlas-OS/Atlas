# Toggle: Automatic Updates (WindowsUpdate AU AUOptions policy).
@{
    Name      = 'AutomaticUpdates'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Automatic Updates\Disable Automatic Updates (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'AUOptions' -Value 2 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Automatic Updates have been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Automatic Updates\Enable Automatic Updates.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'AUOptions'

                if (-not $Toggle.Silent) { Write-Host 'Automatic Updates have been enabled.' }
            }
        }
    }
}
