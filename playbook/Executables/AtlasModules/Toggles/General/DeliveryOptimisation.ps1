# Toggle: Delivery Optimization (DODownloadMode policy).
@{
    Name      = 'DeliveryOptimisation'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Delivery Optimization\Disable Delivery Optimization (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'DODownloadMode' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Delivery Optimization has been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Delivery Optimization\Enable Delivery Optimization.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DODownloadMode' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) { Write-Host 'Delivery Optimization has been enabled.' }
            }
        }
    }
}
