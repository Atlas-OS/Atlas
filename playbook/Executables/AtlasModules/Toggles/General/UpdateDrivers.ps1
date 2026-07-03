# Toggle: Run Update Drivers (plain action launcher, no state recording).
@{
    Name          = 'UpdateDrivers'
    Elevation     = 'Admin'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '2. Drivers\Run Update Drivers.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Update-Drivers.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script
            }
        }
    }
}
