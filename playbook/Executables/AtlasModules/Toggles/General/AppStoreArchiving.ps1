# Toggle: Microsoft Store automatic app archiving.
@{
    Name      = 'AppStoreArchiving'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Store App Archiving\Disable Store App Archiving (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'AllowAutomaticAppArchiving' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'App Store Archiving has been disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Store App Archiving\Enable Store App Archiving.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'AllowAutomaticAppArchiving' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'App Store Archiving has been enabled.'
                }
            }
        }
    }
}
