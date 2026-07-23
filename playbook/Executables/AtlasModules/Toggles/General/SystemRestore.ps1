# Toggle: System Restore.
@{
    Name      = 'SystemRestore'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\System Restore\Disable System Restore.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'DisableSR' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'System Restore has been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\System Restore\Enable System Restore (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' -Name 'DisableSR'

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'System Restore has been enabled.'
                }
            }
        }
    }
}
