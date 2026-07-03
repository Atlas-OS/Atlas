# Toggle: Hibernation (powercfg /h + Start flyout hibernate option).
@{
    Name      = 'Hibernation'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Hibernation\Disable Hibernation (default).cmd'
            Reboot     = 'Prompt'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\powercfg.exe" /h off | Out-Null

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'ShowHibernateOption' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Hibernation has been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Hibernation\Enable Hibernation.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                & "$($Toggle.WinDir)\System32\powercfg.exe" /h on | Out-Null

                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'ShowHibernateOption' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Hibernation has been enabled.' }
            }
        }
    }
}
