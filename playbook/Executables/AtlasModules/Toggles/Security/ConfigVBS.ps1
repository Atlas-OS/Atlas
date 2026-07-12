# Toggle: Show the current VBS configuration once (info only, no state recorded).
@{
    Name          = 'ConfigVBS'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher        = '7. Security\Core Isolation (VBS)\Current Configuration.cmd'
            ToolboxLauncher = 'Scripts\vbsCurrentConfig.cmd'
            Reboot          = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-VbsConfiguration.ps1'
                if (-not [IO.File]::Exists($script)) {
                    throw "Required VBS configuration helper is missing at '$script'."
                }

                $report = & $script
                Write-Host "VBS status: $($report.VbsStatus)"
                Write-Host "Configured services: $($report.ConfiguredServices -join ', ')"
                Write-Host "Running services: $($report.RunningServices -join ', ')"
                Write-Host "Required security properties: $($report.RequiredProperties -join ', ')"
                Write-Host "Available security properties: $($report.AvailableProperties -join ', ')"
            }
        }
    }
}
